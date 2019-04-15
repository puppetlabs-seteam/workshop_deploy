plan workshop_deploy::targets(
  Boolean $bastion = false,
  String $awsregion,
  String $awsuser,
  Integer $amount,
) {
  # Check for Bolt version, as behavior has changed with 1.16, now requiring the user to NOT specify '--run-as root' when calling the plan
  # This change makes the plan incompatible with 1.15 and earlier, so we need to fail the plan if that is the case.
  $r = run_task(workshop_deploy::check_bolt_version, 'localhost', 'Checking version of Bolt...', '_catch_errors' => true)
  unless $r.ok {
    case $r.first.error.kind {
      'puppetlabs.tasks/escalate-error': {
        fail('You need to run this plan without the --run-as root option now!')
      }
      default: { fail('You need to be running at least Bolt 1.16.0 to run this plan!') }
    }
  }


  if $bastion == false {
    notice('Info: Not using the Bastion account for AWS.')
    notice("Info: Using AWS region: ${awsregion}")
    notice("Info: Using AWS user: ${awsuser}")
    run_task(workshop_deploy::awskit_ensure_prereqs, 'localhost', 'Ensuring AWSkit prereqs are met... ' )
    run_script('workshop_deploy/awskit_deploy_targets.sh', 'localhost', 'Deploy workshop targets on AWS using AWSKit... ', 'arguments' => [ "bastion=${bastion}", "awsregion=${awsregion}", "awsuser=${awsuser}", "amount=${amount}" ] )
  }
  elsif $bastion == true {
    notice("Info: Using the Bastion account for AWS, make sure 'source ./scripts/exportcreds.sh' has been run!")
    notice("Info: Using AWS region: ${awsregion}")
    notice("Info: Using AWS user: ${awsuser}")
    $awskeyid   = system::env('AWS_ACCESS_KEY_ID')
    $awssecret  = system::env('AWS_SECRET_ACCESS_KEY')
    $awssession = system::env('AWS_SESSION_TOKEN')
    run_task(workshop_deploy::awskit_ensure_prereqs, 'localhost', 'Ensuring AWSkit prereqs are met... ' )
    run_script('workshop_deploy/awskit_deploy_targets.sh', 'localhost', 'Deploy workshop targets on AWS using AWSKit... ', 'arguments' => [ "bastion=${bastion}", "awsregion=${awsregion}", "awsuser=${awsuser}", "amount=${amount}", "awskeyid=${awskeyid}", "awssecret=${awssecret}", "awssession=${awssession}" ] )
  }
}
