#!/bin/bash
yum list installed puppet-agent
if [ $? -eq 0 ]; then
  echo 'Puppet Agent from PE is already installed, skipping installation.'
else
  cat > ~/pe.conf << FILE
"pe_install::puppet_master_dnsaltnames": ["master"]
"puppet_enterprise::puppet_master_host": "%{::trusted.certname}"
"puppet_enterprise::profile::master::code_manager_auto_configure": true
"puppet_enterprise::profile::master::r10k_remote": "https://github.com/${PT_username}/workshop-control-repo.git"
"puppet_enterprise::profile::master::r10k_private_key": "/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa"
FILE

  sed -i -r -e '/^\s*Defaults\s+secure_path/ s[=(.*)[=\1:/opt/puppetlabs/bin[' /etc/sudoers

  echo '"console_admin_password": "'$PT_admin_pwd'"' >> ~/pe.conf

  mkdir ~/.puppetlabs

  export LANG=en_US.UTF-8
  export LANGUAGE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  cd ~/puppet-enterprise*
  ./puppet-enterprise-installer -p -q -c ~/pe.conf

fi