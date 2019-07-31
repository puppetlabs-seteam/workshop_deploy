plan workshop_deploy::hydra(
  #TargetSpec $master,
  String $demo_name,
  String $github_user,
  String $github_pwd,
) {
  $master = get_targets("${demo_name}master0.classroom.puppet.com")
  run_task(workshop_deploy::check_github_creds, 'localhost', 'Checking Github credentials...', 'username' => $github_user, 'password' => $github_pwd)
  wait_until_available($master, description => 'Verifying PE Master on AWS is available...', wait_time => 30, retry_interval => 5)

  #Make sure CD4PE is not deployed
  $r = run_command('netstat -an | grep 8888', $master, 'Make sure CD4PE is not installed...', '_run_as' => 'root', '_catch_errors' => true)
  if $r.ok {
    fail('You must deploy this Hydra environment **without** CD4PE for the Bolt Workshop!')
  }

  notice('Generating Control Repo student prep scripts...')
  apply_prep($master)
  apply($master, '_run_as' => 'root'){
    file { '/root/prep.ps1':
      ensure  => file,
      content => epp('workshop_deploy/prep_ps1.epp', { 'github_user' => $github_user })
    }
    file { '/root/prep.sh':
      ensure  => file,
      content => epp('workshop_deploy/prep_sh.epp', { 'github_user' => $github_user })
    }
  }

  run_task(workshop_deploy::setup_control_repo, $master, 'Setting up Control Repo...', 'username' => $github_user, 'password' => $github_pwd, '_run_as' => 'root')
  run_task(workshop_deploy::update_codemanager, $master, 'Reconfiguring Code Manager...', 'username' => $github_user, '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $master, 'Run Puppet Agent to apply Code Manager changes...', '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet-code deploy production --wait', $master, 'Deploy Bolt Workshop related Puppet code...', '_run_as' => 'root')
  run_task(workshop_deploy::update_classes, $master, 'Update classes...', 'environment' => 'production', '_run_as' => 'root')
  run_task(workshop_deploy::create_nodegroup, $master, 'Creating Workshop node group...', 'master' => 'puppet.classroom.puppet.com', '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $master, 'Run Puppet Agent to apply classification changes...', '_run_as' => 'root')

  run_task(workshop_deploy::create_webhook_to_aws, $master, 'Creating Webhook...', 'username' => $github_user, 'password' => $github_pwd, '_run_as' => 'root')

  notice("Installation complete, you can login to PE with username 'admin' and password 'puppetlabs'")
}
