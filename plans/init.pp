plan workshop_deploy(
  TargetSpec $nodes,
  String $aws_region,
  String $aws_user,
  String $github_user,
  String $github_pwd,
  String $pe_name = 'master.inf.puppet.vm',
  String $pe_admin_pwd = 'BoltR0cks!',
) {
  apply_prep('localhost')
  #get_targets('localhost').each |$target| {
  #  add_facts($target, { 'aws_region' => $aws_region, 'aws_user' => $aws_user })
  #}
  apply('localhost'){
    include awskit::create_bolt_workshop_master
  }
  
  #run_task(workshop_deploy::awskit_deploy_instance, 'localhost', 'Deploy CentOS instance on AWS using awskit...', 'aws_region' => $aws_region, 'aws_user' => $aws_user)
  wait_until_available($nodes, description => 'Waiting up to 5 minutes until AWS instance becomes available...', wait_time => 300, retry_interval => 15)

  run_task(workshop_deploy::check_github_creds, $nodes, 'Checking Github credentials...', 'username' => $github_user, 'password' => $github_pwd)
  run_task(workshop_deploy::download_pe, $nodes, 'Download latest version of Puppet Enterprise...')
  run_task(workshop_deploy::prep_pe, $nodes, 'Run preparatory steps for Puppet Enterprise...', 'username' => $github_user, 'admin_pwd' => $pe_admin_pwd)

  apply_prep($nodes)

  notice('Installing Prereqs...')
  apply($nodes){
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

  run_command("hostnamectl set-hostname ${pe_name}", $nodes, 'Set Hostname...')

  notice('Updating /etc/hosts...')
  apply($nodes){
    host { $pe_name:
      ensure => present,
      ip     => $facts['ipaddress']
    }
  }

  run_command('ssh-keygen -t rsa -b 4096 -N "" -f /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa', $nodes, 'Generate keys...')
  run_task(workshop_deploy::setup_control_repo, $nodes, 'Setting up Control Repo...', 'username' => $github_user, 'password' => $github_pwd)

  run_task(workshop_deploy::firewall_ports, $nodes, 'Open firewall ports if firewalld is installed...')

  upload_file('workshop_deploy/license.enc', '/etc/puppetlabs/license.enc', $nodes, 'Upload encrypted license key...')
  run_task(workshop_deploy::decode_files, $nodes, 'Decoding encrypted files...')

  notice('Securing key files...')
  apply($nodes){
    file { '/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa':
      mode => '0600',
    }
    file { '/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa.pub':
      mode => '0644',
    }
  }

  upload_file('workshop_deploy/csr_attributes.yaml', '/etc/puppetlabs/puppet/csr_attributes.yaml', $nodes, 'Upload CSR attributes file...')

  run_task(workshop_deploy::install_pe, $nodes, 'Install latest version of Puppet Enterprise...', 'username' => $github_user, 'admin_pwd' => $pe_admin_pwd)
  run_task(workshop_deploy::configure_autosign, $nodes, 'Configure Autosigning...')

  run_command('chown -R pe-puppet:pe-puppet /etc/puppetlabs/puppetserver/ssh', $nodes, 'Set file ownership...')
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $nodes, 'Run Puppet Agent to complete installation...')

  notice('Installing Puppet Bolt...')
  apply($nodes){
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

  run_task(workshop_deploy::generate_token, $nodes, 'Generate RBAC Token...', 'admin_pwd' => $pe_admin_pwd)
  run_command('/opt/puppetlabs/bin/puppet-code deploy production --wait', $nodes, 'Deploy latest Puppet code...')

  run_task(workshop_deploy::update_classes, $nodes, 'Update classes...', 'environment' => 'production')
  run_task(workshop_deploy::create_nodegroup, $nodes, 'Creating Workshop node group...', 'master' => $pe_name)
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $nodes, 'Run Puppet Agent to apply classification changes...')

  run_task(workshop_deploy::create_webhook_to_aws, $nodes, 'Creating Webhook...', 'username' => $github_user, 'password' => $github_pwd)

}
