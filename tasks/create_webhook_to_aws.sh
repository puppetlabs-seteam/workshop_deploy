#!/bin/bash
aws_public_name=$(/opt/puppetlabs/puppet/bin/facter ec2_metadata.public-hostname)
token=$(/opt/puppetlabs/bin/puppet-access show)
json='{
    "active": true,
    "events": [
        "push"
    ],
    "config": {
        "content_type": "json",
        "insecure_ssl": "1",
        "url": "https://'"$aws_public_name"':8170/code-manager/v1/webhook?type=github&token='"$token"'"
    }
}'

if curl --user "${PT_username}":"${PT_password}" -i -s -X POST \
  "https://api.github.com/repos/${PT_username}/workshop-control-repo/hooks" \
  -H 'Content-Type: application/json' \
  -d "${json}" | grep "HTTP/1.1 201 Created"
then
  echo "Webhook successfully created"
else
  echo "Failed to create webhook!"
  exit 1
fi