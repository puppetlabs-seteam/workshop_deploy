plan workshop_deploy::hydra_prep_targets(){
  out::message('Processing Windows nodes...')
  $winnodes = get_targets('allwindows')
  run_task(puppet_agent::install, $winnodes, 'Installing Puppet Agent on Windows...')
  $winnodes.each |$node| {
    $namearray = split($node.name, '[.]')
    run_command("Set-ItemProperty “HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\” –Name Domain –Value 'classroom.puppet.com'", $node, 'Setting Primary DNS Suffix...')
    run_command("Rename-Computer -NewName ${namearray[0]} -Restart -Force", $node, 'Renaming computer to student name...')
  }
  out::message('Windows nodes will now reboot, please allow 5 minutes for this to complete.')
  out::message('Processing Linux nodes...')
  $linnodes = get_targets('alllinux')
  run_task(puppet_agent::install, $linnodes, 'Installing Puppet Agent on Linux...','_run_as' => 'root')
  $linnodes.each |$node| {
    run_command("sed -i -r -e '/^\\s*Defaults\\s+secure_path/ s[=(.*)[=\\1:/opt/puppetlabs/bin[' /etc/sudoers", $node, 'Adding Puppet path to sudoers...', '_run_as' => 'root')
  }
}
