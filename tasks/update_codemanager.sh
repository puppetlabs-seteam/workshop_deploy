#!/bin/bash
code="pe_node_group { 'PE Master':
    ensure             => 'present',
    classes            => {
        'pe_repo::platform::el_7_x86_64' => {},
        'pe_repo::platform::windows_x86_64' => {},
        'puppet_enterprise::profile::master' => {
            'code_manager_auto_configure' => true,
            'r10k_private_key'            => '/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa',
            'r10k_remote'                 => 'https://github.com/${PT_username}/workshop-control-repo.git',
            'replication_mode'            => 'none'
        }
},
    environment        => 'production',
    parent             => 'All Nodes',
    pinned             => ['puppet.classroom.puppet.com'],
    rule               => ['or', ['=', 'name', 'puppet.classroom.puppet.com']],
}"

/opt/puppetlabs/bin/puppet apply -e "${code}"