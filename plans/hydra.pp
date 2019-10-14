plan workshop_deploy::hydra(
  #TargetSpec $master,
  String $demo_name,
  Optional[String[1]] $github_user = undef,
  Optional[String[1]] $github_pwd = undef,
  Optional[String[1]] $github_token = undef,
) {
  if ($github_token) {
    $result = run_task(workshop_deploy::check_github_usertoken, 'localhost', 'Looking up Github username from token...', 'token' => $github_token)
    $github_usr = $result.first.value['_output'].chomp
    warning("Found Github username: ${github_usr}")
    $gh_params = { 'username' => $github_usr, 'token' => $github_token }
  } elsif ($github_user and $github_pwd) {
    $github_usr = $github_user
    $gh_params = { 'username' => $github_usr, 'password' => $github_pwd }
  } else {
    fail_plan('You must specify either a Github username and password, or a personal GitHub access token!')
  }

  $master = get_targets("${demo_name}master0.classroom.puppet.com")
  run_task(workshop_deploy::check_github_creds, 'localhost', 'Checking Github credentials...', $gh_params)
  wait_until_available($master, description => 'Verifying PE Master on AWS is available...', wait_time => 30, retry_interval => 5)

  #Make sure CD4PE is not deployed
  $r = run_command('docker ps | grep cd4pe', $master, 'Make sure CD4PE is not installed...', '_run_as' => 'root', '_catch_errors' => true)
  if $r.ok {
    fail('You must deploy this Hydra environment **without** CD4PE for the Bolt Workshop!')
  }

  notice('Generating Control Repo student prep scripts...')
  apply_prep($master)

  notice('Create prep')
  apply($master, '_run_as' => 'root'){
    file { '/root/prep.ps1':
      ensure  => file,
      content => epp('workshop_deploy/prep_ps1.epp', { 'github_user' => $github_usr })
    }
    file { '/root/prep.sh':
      ensure  => file,
      content => epp('workshop_deploy/prep_sh.epp', { 'github_user' => $github_usr })
    }
  }

  run_task(workshop_deploy::replace_master_control_repo_keys, $master, 'Replacing control repo deploy key', '_run_as' => 'root')
  run_task(workshop_deploy::setup_control_repo, $master, 'Setting up Control Repo...', $gh_params + {'_run_as' => 'root'})
  run_task(workshop_deploy::update_codemanager, $master, 'Reconfiguring Code Manager...', 'username' => $github_usr, '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $master, 'Run Puppet Agent to apply Code Manager changes...', '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet-code deploy production --wait', $master, 'Deploy Bolt Workshop related Puppet code...', '_run_as' => 'root')
  run_task(workshop_deploy::update_classes, $master, 'Update classes...', 'environment' => 'production', '_run_as' => 'root')
  run_task(workshop_deploy::create_nodegroup, $master, 'Creating Workshop node group...', 'master' => 'puppet.classroom.puppet.com', '_run_as' => 'root')
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-splay --no-usecacheonfailure --verbose', $master, 'Run Puppet Agent to apply classification changes...', '_run_as' => 'root')

  run_task(workshop_deploy::create_webhook_to_aws, $master, 'Creating Webhook...', $gh_params + {'_run_as' => 'root'})
  run_task(workshop_deploy::configure_autosign, $master, 'Configure Autosigning...', '_run_as' => 'root')

  warning("Installation complete, you can login to PE with username 'admin' and password 'puppetlabs'")
}
