#!/bin/bash
if curl --user "${PT_username}":"${PT_password}" -i -s -X GET \
  https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks | grep "HTTP/1.1 200 OK"
then
  echo "Credentials verification succeeded"
else
  echo "Credential verification failed!"
  exit 1
fi
