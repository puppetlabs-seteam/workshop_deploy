#!/bin/bash
if [ "${PT_token}" != "" ] ; then
  auth="-H 'Authorization: token ${PT_token}'"
else
  auth="--user '${PT_username}':'${PT_password}'"
fi

if eval curl $auth -i -s -X GET https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks | grep "HTTP/1.1 200 OK"
then
  echo "Credentials verification succeeded"
else
  echo "Credential verification failed!"
  exit 1
fi