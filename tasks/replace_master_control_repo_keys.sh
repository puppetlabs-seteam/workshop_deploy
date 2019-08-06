#!/bin/bash

filename="id-control_repo.rsa"
cd /tmp
ssh-keygen -t rsa -b 2048 -C "root@puppet.classroom.puppet.com" -f /tmp/${filename} -q -N ""

cd /etc/puppetlabs/puppetserver/ssh/
cp "${filename}" "${filename}.bak"
cp "${filename}.pub" "${filename}.pub.bak"
mv "/tmp/${filename}" "${filename}"
mv "/tmp/${filename}.pub" "${filename}.pub"
chmod 600 "${filename}" "${filename}.pub"

exit 0
