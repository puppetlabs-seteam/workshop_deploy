plan workshop_deploy::targets(
  Boolean $bastion = false,
  String $awsregion,
  String $awsuser,
  Integer $amount,
) {
  if $bastion == false {
    notice('Info: Not using the Bastion account for AWS.')
    notice("Info: Using AWS region: ${awsregion}")
    notice("Info: Using AWS user: ${awsuser}")
    run_task(workshop_deploy::awskit_ensure_prereqs, 'localhost', 'Ensuring AWSkit prereqs are met... ' )
    run_task(workshop_deploy::awskit_deploy_targets, 'localhost', 'Deploy workshop targets on AWS using AWSKit... ', 'bastion' => $bastion, 'awsregion' => $awsregion, 'awsuser' => $awsuser, 'amount' => $amount )
  }
  elsif $bastion == true {
    notice("Info: Using the Bastion account for AWS, make sure 'source ./scripts/exportcreds.sh' has been run!")
    notice("Info: Using AWS region: ${awsregion}")
    notice("Info: Using AWS user: ${awsuser}")
    $awskeyid   = system::env('AWS_ACCESS_KEY_ID')
    $awssecret  = system::env('AWS_SECRET_ACCESS_KEY')
    $awssession = system::env('AWS_SESSION_TOKEN')
    run_task(workshop_deploy::awskit_ensure_prereqs, 'localhost', 'Ensuring AWSkit prereqs are met... ' )
    run_task(workshop_deploy::awskit_deploy_targets, 'localhost', 'Deploy workshop targets on AWS using AWSKit... ', 'bastion' => $bastion, 'awsregion' => $awsregion, 'awsuser' => $awsuser, 'amount' => $amount, 'awskeyid' => $awskeyid, 'awssecret' => $awssecret, 'awssession' => $awssession )
  }
}
