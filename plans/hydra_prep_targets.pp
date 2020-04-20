plan workshop_deploy::hydra_prep_targets(){
  out::message('Processing Windows nodes...')
  $winnodes = get_targets('windows')
  run_task(puppet_agent::install, $winnodes, 'Installing Puppet Agent on Windows...', install_options => 'PUPPET_AGENT_STARTUP_MODE=Manual')
  run_command("Set-ItemProperty “HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\” –Name Domain –Value 'classroom.puppet.com'", $winnodes, 'Setting Primary DNS Suffix...')
  $winnodes.each |$node| {
    $namearray = split($node.name, '[.]')
    $result = run_command("if (\$Env:ComputerName -ne '${namearray[0]}') { Rename-Computer -NewName '${namearray[0]}' -Restart -Force }",
      $node, 'Renaming computer to student name...')
  }
  out::message('Windows nodes will now reboot, please allow 5 minutes for this to complete.')
  out::message('Processing Linux nodes...')
  $linnodes = get_targets('linux')
  run_task(puppet_agent::install, $linnodes, 'Installing Puppet Agent on Linux...','_run_as' => 'root')
  run_command("sed -i -r -e '/^\\s*Defaults\\s+secure_path/ s[=(.*)[=\\1:/opt/puppetlabs/bin[' /etc/sudoers", $linnodes, 'Adding Puppet path to sudoers...', '_run_as' => 'root')
}
