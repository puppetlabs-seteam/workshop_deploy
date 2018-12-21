#!/bin/bash
echo ${PT_admin_pwd} | /opt/puppetlabs/bin/puppet-access login --username admin --lifetime 1y
