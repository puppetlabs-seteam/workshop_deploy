#!/bin/bash
/opt/puppetlabs/bin/puppet-infrastructure status
if [ $? -eq 0 ]; then
  echo 'Puppet Enterprise is already installed, skipping installation.'
else
  cat > ~/pe.conf << FILE
"pe_install::puppet_master_dnsaltnames": ["master"]
"puppet_enterprise::puppet_master_host": "%{::trusted.certname}"
"puppet_enterprise::profile::master::code_manager_auto_configure": true
"puppet_enterprise::profile::master::r10k_remote": "https://student0:puppetlabs@${PT_demoname}-gitlab.classroom.puppet.com/puppet/control-repo.git"
"puppet_enterprise::profile::master::r10k_private_key": ""
FILE

  echo '"console_admin_password": "'$PT_admin_pwd'"' >> ~/pe.conf

  export LANG=en_US.UTF-8
  export LANGUAGE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  cd ~/puppet-enterprise*
  ./puppet-enterprise-installer -q -c ~/pe.conf

fi
