#!/bin/bash
# Functions for use in script
#/////////////////////////////////////////////////////////////////////////////////////////////
check_fork_repo() {
  
  if [ "${PT_token}" != "" ] ; then
    cmd="curl -H \"Authorization: token ${PT_token}\""
  else
    cmd="curl --user \"${PT_username}\":\"${PT_password}\""
  fi

  ret=$($cmd -i -s --write-out %{http_code} \
             -X GET https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks | grep -c "HTTP/1.1 200 OK")
             #| grep "HTTP/1.1 200 OK"
  if [ "$ret" -gt "0" ]
  then

    if $cmd -i -X GET \
      https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
      | grep '"full_name": "'$PT_username'/workshop-control-repo'
    then
      get_forked_name
      echo "Target repo ${PT_username}/${repo_name} already exists, deleting it first..." 
      
      ret=$($cmd -i -s -XDELETE \
        "https://api.github.com/repos/${PT_username}/${repo_name}" | grep -c "HTTP/1.1 204 No Content")
      if [ "$ret" -gt "0" ]
      then
        echo "Successfully deleted ${PT_username}/${repo_name}"
        echo "Sleeping for 10 seconds..."
        sleep 10
      else
        echo "Error trying to delete ${PT_username}/${repo_name}! Exiting..."
        exit 1
      fi
    fi
  else
    echo "Failed to retrieve forks for puppetlabs-seteam/workshop-control-repo! ($ret)"
    exit 1
  fi
}

fork_repo() {
  org=$1
  json='{ "organisation": "'${org}'" }'

  if [ "${PT_token}" != "" ] ; then
    cmd="curl -H \"Authorization: token ${PT_token}\""
  else
    cmd="curl --user \"${PT_username}\":\"${PT_password}\""
  fi

  ret=$($cmd -i -s -X POST -H "Content-Type: application/json" -d "${json}" \
         https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks | grep -c "HTTP/1.1 202 Accepted")
  if [ "$ret" -gt "0" ]
  then
    echo "Fork of workshop-control-repo successfully created in ${org}"
    echo "Sleeping for 10 seconds...."
    sleep 10
    get_forked_name
  else
    echo "Failed to create fork of workshop-control-repo in ${org} - ${ret}!"
    exit 1
  fi
}

get_forked_name() {
  
  if [ "${PT_token}" != "" ] ; then
    cmd="curl -H \"Authorization: token ${PT_token}\""
  else
    cmd="curl --user \"${PT_username}\":\"${PT_password}\""
  fi

  repo_name=$($cmd -i -X GET \
    https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
    | awk '/full_name": "'${PT_username}'/ {print $2}' | awk -F '/' '{print $2}' | awk -F '"' '{print $1}')
}

create_branch() {
  branch=$1
  sha=$2
  echo "Checking if branch ${branch} already exists..."

  if [ "${PT_token}" != "" ] ; then
    cmd="curl -H \"Authorization: token ${PT_token}\""
  else
    cmd="curl --user \"${PT_username}\":\"${PT_password}\""
  fi
  
  if $cmd -i -s -X GET \
    "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/${branch}" \
    | grep "HTTP/1.1 200 OK"
  then
    echo "Branch ${branch} already exists, deleting it first..."
    if $cmd -i -s -X DELETE \
      "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/${branch}" \
      | grep "HTTP/1.1 204 No Content"
    then
      echo "Successfully deleted branch ${branch} from ${PT_username}/${repo_name}"
    else
      echo "Error trying to delete branch ${branch} from ${PT_username}/${repo_name}! Exiting..."
      exit 1
    fi
  fi
  json='{"ref": "refs/heads/'$branch'","sha": "'$sha'"}'
  if $cmd -i -s -X POST \
    "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs" \
    -H 'Content-Type: application/json' \
    -d "${json}" | grep "HTTP/1.1 201 Created"
  then
    echo "Successfully created branch: ${branch}"
  else
    echo "Failed to create branch: ${branch}!"
    exit 1
  fi
}

protect_branch() {
  branch=$1
  json='{
    "required_status_checks": null,
    "enforce_admins": true,
    "required_pull_request_reviews": null,
    "restrictions": null
  }'

  if [ "${PT_token}" != "" ] ; then
    cmd="curl -H \"Authorization: token ${PT_token}\""
  else
    cmd="curl --user \"${PT_username}\":\"${PT_password}\""
  fi

  if $cmd -i -s -X PUT \
    "https://api.github.com/repos/${PT_username}/${repo_name}/branches/${branch}/protection" \
    -H 'Content-Type: application/json' \
    -d "${json}" | grep "HTTP/1.1 200 OK"
  then
    echo "Successfully protected branch ${branch}"
  else
    echo "Failed to protect branch ${branch}!"
    exit 1
  fi
}

change_default_branch() {
  branch=$1
  json='{
    "name": "'$repo_name'",
    "default_branch": "'$branch'"
  }'

  if [ "${PT_token}" != "" ] ; then
    cmd="curl -H \"Authorization: token ${PT_token}\""
  else
    cmd="curl --user \"${PT_username}\":\"${PT_password}\""
  fi

  if $cmd -i -s -X PATCH \
    "https://api.github.com/repos/${PT_username}/${repo_name}" \
    -H 'Content-Type: application/json' \
    -d "${json}" | grep "HTTP/1.1 200 OK"
  then
    echo "Successfully changed default branch to ${branch}"
  else
    echo "Failed to change default branch to ${branch}!"
    exit 1
  fi
}

add_deploy_key() {
  json='{
    "title": "'$1'",
    "key": "'$2'",
    "read_only": false
  }'

  if [ "${PT_token}" != "" ] ; then
    cmd="curl -H \"Authorization: token ${PT_token}\""
  else
    cmd="curl --user \"${PT_username}\":\"${PT_password}\""
  fi

  if $cmd -i -s -X POST \
    "https://api.github.com/repos/${PT_username}/${repo_name}/keys" \
    -H 'Content-Type: application/json' \
    -d "${json}" | grep "HTTP/1.1 201 Created"
  then
    echo "Successfully added RSA deploy key"
  else
    echo "Failed to add RSA deploy key!"
    exit 1
  fi
}

create_file() {
  json='{
    "message": "Add file",
    "content": "'$2'"
  }'

  if [ "${PT_token}" != "" ] ; then
    cmd="curl -H \"Authorization: token ${PT_token}\""
  else
    cmd="curl --user \"${PT_username}\":\"${PT_password}\""
  fi

  if $cmd -i -s -X PUT \
    "https://api.github.com/repos/${PT_username}/${repo_name}/contents/$1" \
    -H 'Content-Type: application/json' \
    -d "${json}" | grep "HTTP/1.1 201 Created"
  then
    echo "Successfully created file ${1} in control repo"
  else
    echo "Failed to create file ${1} in control repo!"
    exit 1
  fi
}

#/////////////////////////////////////////////////////////////////////////////////////////////
# End of functions for use in script

# Main script execution
if [ "${PT_token}" != "" ] ; then
  cmd="curl -H \"Authorization: token ${PT_token}\""
else
  cmd="curl --user \"${PT_username}\":\"${PT_password}\""
fi

check_fork_repo
fork_repo $PT_username

sha_id=$($cmd -X GET \
  "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/workshop_init" \
  | grep '"sha"' | awk '{split($0,a, "\""); print a[4]}')

create_branch production $sha_id
protect_branch workshop_init
change_default_branch production

rsa_key=$(cat /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa.pub)
add_deploy_key "workshop@puppet" "${rsa_key}"

base64 -i /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa > ~/workshop_key.enc
encrypted_key=$(base64 -i -w0 ~/workshop_key.enc)
create_file "workshop_key.enc" "${encrypted_key}"

prep_ps1=$(base64 -i -w0 ~/prep.ps1)
create_file "prep.ps1" "${prep_ps1}"

prep_sh=$(base64 -i -w0 ~/prep.sh)
create_file "prep.sh" "${prep_sh}"
