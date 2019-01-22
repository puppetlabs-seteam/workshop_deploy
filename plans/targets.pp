plan workshop_deploy(
  TargetSpec $nodes,
  String $awsregion,
  String $awsuser,
  Integer $amount,
) {
  $localhost = get_targets('localhost')
  apply_prep('localhost')
  add_facts($localhost[0], { 'aws_region' => $awsregion, 'user' => $awsuser })
  notice("Deploy workshop targets on AWS using awskit...")
  apply($localhost){
    class {'awskit::create_bolt_workshop_targets': count => $amount }
  }
}
