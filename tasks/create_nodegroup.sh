#!/bin/bash
code="pe_node_group { 'Workshop':
  ensure      => 'present',
  classes     => {
    'role::workshop' => {},
  },
  environment => 'production',
  parent      => 'All Nodes',
  pinned      => ['${PT_master}'],
}"

/opt/puppetlabs/bin/puppet apply -e "${code}"
