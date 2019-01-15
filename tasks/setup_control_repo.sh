#!/bin/bash
# Functions for use in script
#/////////////////////////////////////////////////////////////////////////////////////////////
check_fork_repo() {
  if curl --user "${PT_username}":"${PT_password}" -i -s -X GET \
    https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
    | grep "HTTP/1.1 200 OK"
  then
    if curl --user "${PT_username}":"${PT_password}" -i -X GET \
      https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
      | grep '"full_name": "'$PT_username'/workshop-control-repo"'
    then
      echo "Target repo ${PT_username}/workshop-control-repo already exists, deleting it first..." 
      if curl --user "${PT_username}":"${PT_password}" -i -s -X DELETE \
        "https://api.github.com/repos/${PT_username}/workshop-control-repo" \
        | grep "HTTP/1.1 204 No Content"
      then
        echo "Successfully deleted ${PT_username}/workshop-control-repo"
      else
        echo "Error trying to delete ${PT_username}/workshop-control-repo! Exiting..."
        exit 1
      fi
    fi
  else
    echo "Failed to retrieve forks for puppetlabs-seteam/workshop-control-repo!"
    exit 1
  fi
}

fork_repo() {
  org=$1
  json='{
      "organisation": "'$org'"
  }'

  if curl --user "${PT_username}":"${PT_password}" -i -s -X POST \
    https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
    -H 'Content-Type: application/json' \
    -d "${json}" | grep "HTTP/1.1 202 Accepted"
  then
    echo "Fork of workshop-control-repo successfully created in ${org}"
    echo "Sleeping for 10 seconds..."
    sleep 10
  else
    echo "Failed to create fork of workshop-control-repo in ${org}!"
    exit 1
  fi
}

create_branch() {
  branch=$1
  sha=$2
  echo "Checking if branch ${branch} already exists..."
  if curl --user "${PT_username}":"${PT_password}" -i -s -X GET \
    "https://api.github.com/repos/${PT_username}/workshop-control-repo/git/refs/heads/${branch}" \
    | grep "HTTP/1.1 200 OK"
  then
    echo "Branch ${branch} already exists, deleting it first..."
    if curl --user "${PT_username}":"${PT_password}" -i -s -X DELETE \
      "https://api.github.com/repos/${PT_username}/workshop-control-repo/git/refs/heads/${branch}" \
      | grep "HTTP/1.1 204 No Content"
    then
      echo "Successfully deleted branch ${branch} from ${PT_username}/workshop-control-repo"
    else
      echo "Error trying to delete branch ${branch} from ${PT_username}/workshop-control-repo! Exiting..."
      exit 1
    fi
  fi
  json='{"ref": "refs/heads/'$branch'","sha": "'$sha'"}'
  if curl --user "${PT_username}":"${PT_password}" -i -s -X POST \
    "https://api.github.com/repos/${PT_username}/workshop-control-repo/git/refs" \
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

  if curl --user "${PT_username}":"${PT_password}" -i -s -X PUT \
    "https://api.github.com/repos/${PT_username}/workshop-control-repo/branches/${branch}/protection" \
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
    "name": "workshop-control-repo",
    "default_branch": "'$branch'"
  }'

  if curl --user "${PT_username}":"${PT_password}" -i -s -X PATCH \
    "https://api.github.com/repos/${PT_username}/workshop-control-repo" \
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
  $key=$1
  json='{
    "title": "workshop@puppet",
    "key": "'$key'",
    "read_only": true
  }'

  if curl --user "${PT_username}":"${PT_password}" -i -s -X GET \
    "https://api.github.com/repos/${PT_username}/workshop-control-repo/keys/1" \
    | grep "HTTP/1.1 200 OK"
  then
    echo "Existing key detected, removing it first..."
    if curl --user "${PT_username}":"${PT_password}" -i -s -X DELETE \
      "https://api.github.com/repos/${PT_username}/workshop-control-repo/keys/1" \
      | grep "HTTP/1.1 204 No Content"
    then
      echo "Successfully deleted key 1 from ${PT_username}/workshop-control-repo"
    else
      echo "Error trying to delete key 1 from ${PT_username}/workshop-control-repo! Exiting..."
      exit 1
    fi 
  fi

  if curl --user "${PT_username}":"${PT_password}" -i -s -X POST \
    "https://api.github.com/repos/${PT_username}/workshop-control-repo/keys" \
    -H 'Content-Type: application/json' \
    -d "${json}" | grep "HTTP/1.1 201 Created"
  then
    echo "Successfully added RSA deploy key"
  else
    echo "Failed to add RSA deploy key!"
    exit 1
  fi
}
#/////////////////////////////////////////////////////////////////////////////////////////////
# End of functions for use in script

# Main script execution
check_fork_repo
fork_repo $PT_username

sha_id=$(curl --user "${PT_username}":"${PT_password}" -X GET \
  "https://api.github.com/repos/${PT_username}/workshop-control-repo/git/refs/heads/workshop_init" \
  | grep '"sha"' | awk '{split($0,a, "\""); print a[4]}')

create_branch master $sha_id
create_branch production $sha_id
protect_branch workshop_init
change_default_branch master
add_deploy_key $(cat /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa.pub)