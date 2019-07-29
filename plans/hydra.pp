plan workshop_deploy::hydra(
  String $github_user,
  String $github_pwd,
) {
  run_task(workshop_deploy::check_github_creds, 'localhost', 'Checking Github credentials...', 'username' => $github_user, 'password' => $github_pwd)

  notice('Generating Control Repo student prep scripts...')
  
  apply_prep('localhost')
  apply('localhost'){
    file { "/Users/${facts['identity']['user']}/prep.ps1":
      ensure  => file,
      content => epp('workshop_deploy/prep_ps1.epp', { 'github_user' => $github_user })
    }
    file { "/Users/${facts['identity']['user']}/prep.sh":
      ensure  => file,
      content => epp('workshop_deploy/prep_sh.epp', { 'github_user' => $github_user })
    }
  }

  run_task(workshop_deploy::setup_control_repo, 'localhost', 'Setting up Control Repo...', 'username' => $github_user, 'password' => $github_pwd)
}
