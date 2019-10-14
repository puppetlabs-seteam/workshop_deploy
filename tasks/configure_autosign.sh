#!/bin/bash

AUTOSIGN_FILE=/etc/puppetlabs/puppet/autosign.conf

echo "*.compute.internal" > $AUTOSIGN_FILE
echo "*.classroom.puppet.com" >> $AUTOSIGN_FILE

autosign_setting=$(puppet config print autosign --section master)

if [ "${autosign_setting}" != "${AUTOSIGN_FILE}" ] ; then
  echo "Autosign set to ${autosign_setting}, needs to be $AUTOSIGN_FILE"
  echo "Setting autosign to $AUTOSIGN_FILE..."
  puppet config set autosign "$AUTOSIGN_FILE" --section master
  echo "Restarting puppetserver for new setting to take effect..."
  systemctl restart pe-puppetserver
fi