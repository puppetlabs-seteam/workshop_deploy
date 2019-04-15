plan workshop_deploy(
  TargetSpec $nodes,
  String $awsregion,
  String $awsuser,
  String $github_user,
  String $github_pwd,
  String $pe_name = 'master.inf.puppet.vm',
  String $pe_admin_pwd = 'BoltR0cks!',
  Boolean $bastion = false,
) {
  # Check for Bolt version, as behavior has changed with 1.16, now requiring the user to NOT specify '--run-as root' when calling the plan
  # This change makes the plan incompatible with 1.15 and earlier, so we need to fail the plan if that is the case.
  $r = run_task('workshop_deploy/check_bolt_version.sh', 'localhost', 'Checking version of Bolt...', '_catch_errors' => true)
  unless $r.ok {
    fail('You need to be running at least Bolt 1.16.0 to run this plan!')
  }

  if $bastion == false {
    notice('Info: Not using the Bastion account for AWS.')
    notice("Info: Using AWS region: ${awsregion}")
    notice("Info: Using AWS user: ${awsuser}")
    $r = run_task(workshop_deploy::awskit_ensure_prereqs, 'localhost', 'Ensuring AWSkit prereqs are met... ' )
    if $r.error.kind == 'puppetlabs.tasks/escalate-error' {
      fail('You need to run this plan without the "--run-as root" option now!')
    }
    run_script('workshop_deploy/awskit_deploy_master.sh', 'localhost', 'Deploy workshop PE Master on AWS using AWSKit... ', 'arguments' => [ "bastion=${bastion}", "awsregion=${awsregion}", "awsuser=${awsuser}" ] )
  }
  elsif $bastion == true {
    notice("Info: Using the Bastion account for AWS, make sure 'source ./scripts/exportcreds.sh' has been run!")
    notice("Info: Using AWS region: ${awsregion}")
    notice("Info: Using AWS user: ${awsuser}")
    $awskeyid   = system::env('AWS_ACCESS_KEY_ID')
    $awssecret  = system::env('AWS_SECRET_ACCESS_KEY')
    $awssession = system::env('AWS_SESSION_TOKEN')
    run_task(workshop_deploy::awskit_ensure_prereqs, 'localhost', 'Ensuring AWSkit prereqs are met... ' )
    run_script('workshop_deploy/awskit_deploy_master.sh', 'localhost', 'Deploy workshop PE Master on AWS using AWSKit... ', 'arguments' => [ "bastion=${bastion}", "awsregion=${awsregion}", "awsuser=${awsuser}", "awskeyid=${awskeyid}", "awssecret=${awssecret}", "awssession=${awssession}" ] )
  }

  wait_until_available($nodes, description => 'Waiting up to 5 minutes until AWS instance becomes available...', wait_time => 300, retry_interval => 15)

  run_task(workshop_deploy::check_github_creds, $nodes, 'Checking Github credentials...', 'username' => $github_user, 'password' => $github_pwd, '_run_as' => 'root')
  run_task(workshop_deploy::download_pe, $nodes, 'Download latest version of Puppet Enterprise...', '_run_as' => 'root')
  run_task(workshop_deploy::prep_pe, $nodes, 'Run preparatory steps for Puppet Enterprise...', 'username' => $github_user, 'admin_pwd' => $pe_admin_pwd, '_run_as' => 'root')

  apply_prep($nodes)

  notice('Installing Prereqs...')
  apply($nodes, '_run_as' => 'root'){
    $packages = [
      'wget',
      'nano',
      'less',
      'cronie',
      'openssh-clients',
      'openssh-server',
      'openssh',
      'openssl',
      'cifs-utils'
    ]

    package { $packages:
      ensure => 'present'
    }

    file { '/etc/puppetlabs':
      ensure => directory
    }

    file { '/etc/puppetlabs/puppet':
      ensure => directory
    }

    file { '/etc/puppetlabs/puppetserver':
      ensure => directory
    }

    file { '/etc/puppetlabs/puppetserver/ssh':
      ensure => directory
    }
  }

  run_command("hostnamectl set-hostname ${pe_name}", $nodes, 'Set Hostname...', '_run_as' => 'root')

  notice('Updating /etc/hosts...')
  apply($nodes, '_run_as' => 'root'){
    host { $pe_name:
      ensure => present,
      ip     => $facts['ipaddress']
    }
  }

  run_task(workshop_deploy::generate_keys, $nodes, 'Generate SSH keys...', '_run_as' => 'root')

  notice('Generating Control Repo student prep scripts...')
  apply($nodes, '_run_as' => 'root'){
    file { '/root/prep.ps1':
      ensure  => file,
      content => epp('workshop_deploy/prep_ps1.epp', { 'github_user' => $github_user })
    }
    file { '/root/prep.sh':
      ensure  => file,
      content => epp('workshop_deploy/prep_sh.epp', { 'github_user' => $github_user })
    }
  }

  run_task(workshop_deploy::setup_control_repo, $nodes, 'Setting up Control Repo...', 'username' => $github_user, 'password' => $github_pwd, '_run_as' => 'root')

  run_task(workshop_deploy::firewall_ports, $nodes, 'Open firewall ports if firewalld is installed...', '_run_as' => 'root')

  upload_file('workshop_deploy/license.enc', '/etc/puppetlabs/license.enc', $nodes, 'Upload encrypted license key...', '_run_as' => 'root')
  run_task(workshop_deploy::decode_files, $nodes, 'Decoding encrypted files...', '_run_as' => 'root')

  notice('Securing key files...')
  apply($nodes, '_run_as' => 'root'){
    file { '/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa':
      mode => '0600',
    }
    file { '/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa.pub':
      mode => '0644',
    }
  }

  upload_file('workshop_deploy/csr_attributes.yaml', '/etc/puppetlabs/puppet/csr_attributes.yaml', $nodes, 'Upload CSR attributes file...', '_run_as' => 'root')

  run_task(workshop_deploy::install_pe, $nodes, 'Install latest version of Puppet Enterprise...', 'username' => $github_user, 'admin_pwd' => $pe_admin_pwd, '_run_as' => 'root')
  run_task(workshop_deploy::configure_autosign, $nodes, 'Configure Autosigning...', '_run_as' => 'root')

  run_command('chown -R pe-puppet:pe-puppet /etc/puppetlabs/puppetserver/ssh', $nodes, 'Set file ownership...', '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $nodes, 'Run Puppet Agent to complete installation...', '_run_as' => 'root')

  notice('Installing Puppet Bolt...')
  apply($nodes, '_run_as' => 'root'){
    yumrepo { 'puppet6':
      ensure   => 'present',
      name     => 'puppet6',
      descr    => 'Puppet 6 Repository el 7 - $basearch',
      baseurl  => 'http://yum.puppetlabs.com/puppet6/el/7/$basearch',
      gpgkey   => 'file:///opt/puppetlabs/server/data/packages/public/GPG-KEY-puppet',
      enabled  => '1',
      gpgcheck => '1',
      target   => '/etc/yum.repo.d/puppet6.repo',
    }
    package { 'puppet-bolt':
      ensure  => 'present',
      require => Yumrepo['puppet6']
    }
  }

  run_task(workshop_deploy::generate_token, $nodes, 'Generate RBAC Token...', 'admin_pwd' => $pe_admin_pwd, '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet-code deploy production --wait', $nodes, 'Deploy latest Puppet code...', '_run_as' => 'root')

  run_task(workshop_deploy::update_classes, $nodes, 'Update classes...', 'environment' => 'production', '_run_as' => 'root')
  run_task(workshop_deploy::create_nodegroup, $nodes, 'Creating Workshop node group...', 'master' => $pe_name, '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $nodes, 'Run Puppet Agent to apply classification changes...', '_run_as' => 'root')

  run_task(workshop_deploy::create_webhook_to_aws, $nodes, 'Creating Webhook...', 'username' => $github_user, 'password' => $github_pwd, '_run_as' => 'root')

  notice("Installation complete, you can login to PE with username 'admin' and password '${pe_admin_pwd}'")
}
