#!/bin/bash
if [ ! -f /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa ]
then
  ssh-keygen -t rsa -b 4096 -N "" -f /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa
fi
