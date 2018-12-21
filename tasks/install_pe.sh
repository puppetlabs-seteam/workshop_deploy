#!/bin/bash
/opt/puppetlabs/bin/puppet-infrastructure status
if [ $? -eq 0 ]; then
  echo 'Puppet Enterprise is already installed, skipping installation.'
else
  cat > ~/pe.conf << FILE
"puppet_enterprise::puppet_master_host": "%{::trusted.certname}"
"puppet_enterprise::profile::master::code_manager_auto_configure": true
"puppet_enterprise::profile::master::r10k_remote": "https://github.com/puppetlabs-seteam/workshop-control-repo.git"
"puppet_enterprise::profile::master::r10k_private_key": "/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa"
FILE

  echo '"console_admin_password": "'$PT_admin_pwd'"' >> ~/pe.conf

  export LANG=en_US.UTF-8
  export LANGUAGE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  cd ~/puppet-enterprise*
  ./puppet-enterprise-installer -q -c ~/pe.conf

fi