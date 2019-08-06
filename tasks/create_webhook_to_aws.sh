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

if [ "${PT_token}" != "" ] 
then

  repo_name=$(curl -H "Authorization: token ${PT_token}" -i -X GET \
      https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
      | awk '/full_name": "'${PT_username}'/ {print $2}' | awk -F '/' '{print $2}' | awk -F '"' '{print $1}')

else

  repo_name=$(curl --user "${PT_username}":"${PT_password}" -i -X GET \
      https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
      | awk '/full_name": "'${PT_username}'/ {print $2}' | awk -F '/' '{print $2}' | awk -F '"' '{print $1}')

fi

rm -f /tmp/curl.$$

if [ "${PT_token}" != "" ] 
then

  curl -H "Authorization: token ${PT_token}" -i -s -X POST \
      "https://api.github.com/repos/${PT_username}/${repo_name}/hooks" \
      -H 'Content-Type: application/json' \
      -d "${json}" -o /tmp/curl.$$

else

  curl --user "${PT_username}":"${PT_password}" -i -s -X POST \
      "https://api.github.com/repos/${PT_username}/${repo_name}/hooks" \
      -H 'Content-Type: application/json' \
      -d "${json}" -o /tmp/curl.$$

fi

if grep "HTTP/1.1 201 Created" /tmp/curl.$$
then

  echo "Webhook successfully created"
  rm -f /tmp/curl.$$

else

  echo "Failed to create webhook!"
  cat /tmp/curl.$$
  rm -f /tmp/curl.$$
  exit 1

fi
