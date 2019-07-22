#!/bin/bash
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
echo ${PT_admin_pwd} | /opt/puppetlabs/bin/puppet-access login --username admin --lifetime 1y
