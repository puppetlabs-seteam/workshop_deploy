plan workshop_deploy::multimaster(
  TargetSpec $nodes,
  String $demo_name,
  String $pe_admin_pwd = 'BoltR0cks!',
) {

  wait_until_available($nodes, description => 'Waiting up to 5 minutes until AWS instances become available...', wait_time => 300, retry_interval => 15)

  run_task(workshop_deploy::download_pe, $nodes, 'Download latest version of Puppet Enterprise...', '_run_as' => 'root')
  run_task(workshop_deploy::prep_pe, $nodes, 'Run preparatory steps for Puppet Enterprise...', 'demoname' => $demo_name, 'admin_pwd' => $pe_admin_pwd, '_run_as' => 'root')

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

  run_task(workshop_deploy::generate_keys, $nodes, 'Generate SSH keys...', '_run_as' => 'root')

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

  run_task(workshop_deploy::generate_token, $nodes, 'Generate RBAC Token...', 'admin_pwd' => $pe_admin_pwd, '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet-code deploy production --wait', $nodes, 'Deploy latest Puppet code...', '_run_as' => 'root')

  run_task(workshop_deploy::update_classes, $nodes, 'Update classes...', 'environment' => 'production', '_run_as' => 'root')
  run_task(workshop_deploy::create_nodegroup, $nodes, 'Creating Workshop node group...', 'master' => $pe_name, '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $nodes, 'Run Puppet Agent to apply classification changes...', '_run_as' => 'root')

  run_task(workshop_deploy::create_webhook_to_aws, $nodes, 'Creating Webhook...', 'username' => $github_user, 'password' => $github_pwd, '_run_as' => 'root')

  notice("Installation complete, you can login to PE with username 'admin' and password '${pe_admin_pwd}'")
}
