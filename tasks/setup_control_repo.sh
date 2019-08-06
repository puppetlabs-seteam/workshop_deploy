#!/bin/bash

# Functions for use in script
#/////////////////////////////////////////////////////////////////////////////////////////////

check_fork_repo() {
  
  rm -f /tmp/curl.$$
  if [ "${PT_token}" != "" ] ; then
    curl -H "Authorization: token ${PT_token}" -i -s --write-out %{http_code} \
             -X GET https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks -o /tmp/curl.$$
  else
    curl --user "${PT_username}":"${PT_password}" -i -s --write-out %{http_code} \
             -X GET https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks -o /tmp/curl.$$
  fi

  if grep -c "HTTP/1.1 200 OK" /tmp/curl.$$
  then

    rm -f /tmp/curl.$$

    if [ "${PT_token}" != "" ] ; then
      curl -H "Authorization: token ${PT_token}" -i -X GET \
           https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks -o /tmp/curl.$$
    else
      curl --user "${PT_username}":"${PT_password}" -i -X GET \
          https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks -o /tmp/curl.$$
    fi

    if grep '"full_name": "'$PT_username'/workshop-control-repo' /tmp/curl.$$
    then

      rm -f /tmp/curl.$$

      get_forked_name
      echo "Target repo ${PT_username}/${repo_name} already exists, deleting it first..." 

      if [ "${PT_token}" != "" ] ; then
        curl -H "Authorization: token ${PT_token}" -i -s -X DELETE \
             "https://api.github.com/repos/${PT_username}/${repo_name}" -o /tmp/curl.$$
      else
        curl --user "${PT_username}":"${PT_password}" -i -s -X DELETE \
             "https://api.github.com/repos/${PT_username}/${repo_name}" -o /tmp/curl.$$
      fi
      
      if grep -c "HTTP/1.1 204 No Content" /tmp/curl.$$
      then

        echo "Successfully deleted ${PT_username}/${repo_name}"
        echo "Sleeping for 10 seconds..."
        sleep 10
        rm -f /tmp/curl.$$

      else

        rm -f /tmp/curl.$$
        echo "Error trying to delete ${PT_username}/${repo_name}! Exiting..."
        exit 1

      fi

    fi

  else

    rm -f /tmp/curl.$$
    echo "Failed to retrieve forks for puppetlabs-seteam/workshop-control-repo! ($ret)"
    exit 1

  fi
}

fork_repo() {
  org=$1
  json='{ "organisation": "'${org}'" }'

  rm -f /tmp/curl.$$

  if [ "${PT_token}" != "" ] ; then

    curl -i -s -H "Content-Type: application/json" -H "Authorization: token ${PT_token}" \
         -X POST https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
         -d "${json}" -o /tmp/curl.$$

  else

    curl --user \"${PT_username}\":\"${PT_password}\" -i -s -H "Content-Type: application/json" \
         -X POST https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
         -d "${json}" -o /tmo/curl.$$

  fi

  if grep -c "HTTP/1.1 202 Accepted" /tmp/curl.$$
  then

    rm -f /tmp/curl.$$
    echo "Fork of workshop-control-repo successfully created in ${org}"
    echo "Sleeping for 10 seconds...."
    sleep 10
    get_forked_name

  else

    echo "Failed to create fork of workshop-control-repo in ${org}!"
    cat /tmp/curl.$$
    rm -f /tmp/curl.$$
    exit 1

  fi
}

get_forked_name() {

  if [ "${PT_token}" != "" ] ; then

    repo_name=$(curl -H "Authorization: token ${PT_token}" -i -X GET \
         https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
         | awk '/full_name": "'${PT_username}'/ {print $2}' | awk -F '/' '{print $2}' | awk -F '"' '{print $1}')

  else

    repo_name=$(curl --user "${PT_username}":"${PT_password}" -i -X GET \
         https://api.github.com/repos/puppetlabs-seteam/workshop-control-repo/forks \
         | awk '/full_name": "'${PT_username}'/ {print $2}' | awk -F '/' '{print $2}' | awk -F '"' '{print $1}')

  fi

}

create_branch() {
  branch=$1
  sha=$2

  rm -f /tmp/curl.$$

  echo "Checking if branch ${branch} already exists..."

  if [ "${PT_token}" != "" ] ; then
    curl -H "Authorization: token ${PT_token}" -i -s -X GET \
         "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/${branch}" -o /tmp/curl.$$
  else
    curl --user "${PT_username}":"${PT_password}" -i -s -X GET \
         "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/${branch}" -o /tmp/curl.$$
  fi
  
  if grep "HTTP/1.1 200 OK" /tmp/curl.$$
  then
    echo "Branch ${branch} already exists, deleting it first..."
    rm -f /tmp/curl.$$

    if [ "${PT_token}" != "" ] ; then
      curl -H "Authorization: token ${PT_token}" -i -s -X DELETE \
           "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/${branch}" -o /tmp/curl.$$
    else
      curl --user "${PT_username}":"${PT_password}" -i -s -X DELETE \
           "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/${branch}" -o /tmp/curl.$$
    fi

    if grep "HTTP/1.1 204 No Content" /tmp/curl.$$
    then
      echo "Successfully deleted branch ${branch} from ${PT_username}/${repo_name}"
      rm -f /tmp/curl.$$
    else
      echo "Error trying to delete branch ${branch} from ${PT_username}/${repo_name}! Exiting..."
      rm -f /tmp/curl.$$
      exit 1
    fi
  fi

  json='{"ref": "refs/heads/'$branch'","sha": "'$sha'"}'

  if [ "${PT_token}" != "" ] ; then
    curl -H "Authorization: token ${PT_token}" -i -s -X POST \
        "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs" \
        -H 'Content-Type: application/json' \
        -d "${json}" -o /tmp/curl.$$
  else
    curl --user "${PT_username}":"${PT_password}" -i -s -X POST \
        "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs" \
        -H 'Content-Type: application/json' \
        -d "${json}" -o /tmp/curl.$$
  fi

  if grep "HTTP/1.1 201 Created" /tmp/curl.$$
  then
    echo "Successfully created branch: ${branch}"
    rm -f /tmp/curl.$$
  else
    echo "Failed to create branch: ${branch}!"
    rm -f /tmp/curl.$$
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

  rm -f /tmp/curl.$$

  if [ "${PT_token}" != "" ] ; then
    curl -H "Authorization: token ${PT_token}" -i -s -X PUT \
    "https://api.github.com/repos/${PT_username}/${repo_name}/branches/${branch}/protection" \
    -H 'Content-Type: application/json' \
    -d "${json}" -o /tmp/curl.$$
  else
    curl --user "${PT_username}":"${PT_password}" -i -s -X PUT \
    "https://api.github.com/repos/${PT_username}/${repo_name}/branches/${branch}/protection" \
    -H 'Content-Type: application/json' \
    -d "${json}" -o /tmp/curl.$$
  fi

  if grep "HTTP/1.1 200 OK" /tmp/curl.$$
  then
    echo "Successfully protected branch ${branch}"
    rm -f /tmp/curl.$$
  else
    echo "Failed to protect branch ${branch}!"
    rm -f /tmp/curl.$$
    exit 1
  fi
}

change_default_branch() {
  branch=$1
  json='{
    "name": "'$repo_name'",
    "default_branch": "'$branch'"
  }'

  rm -f /tmp/curl.$$

  if [ "${PT_token}" != "" ] ; then
    curl -H "Authorization: token ${PT_token}" -i -s -X PATCH \
    "https://api.github.com/repos/${PT_username}/${repo_name}" \
    -H 'Content-Type: application/json' \
    -d "${json}" -o /tmp/curl.$$
  else
    curl --user "${PT_username}":"${PT_password}" -i -s -X PATCH \
    "https://api.github.com/repos/${PT_username}/${repo_name}" \
    -H 'Content-Type: application/json' \
    -d "${json}" -o /tmp/curl.$$
  fi

  if grep "HTTP/1.1 200 OK" /tmp/curl.$$
  then
    echo "Successfully changed default branch to ${branch}"
    rm -f /tmp/curl.$$
  else
    echo "Failed to change default branch to ${branch}!"
    rm -f /tmp/curl.$$
    exit 1
  fi
}

add_deploy_key() {
  json='{
    "title": "'$1'",
    "key": "'$2'",
    "read_only": false
  }'

  rm -f /tmp/curl.$$

  if [ "${PT_token}" != "" ] ; then
    curl -H 'Content-Type: application/json'  -H "Authorization: token ${PT_token}" -i -s -X POST \
        "https://api.github.com/repos/${PT_username}/${repo_name}/keys" \
        -d "${json}" -o /tmp/curl.$$
  else
    curl --user "${PT_username}":"${PT_password}" -i -s -X POST \
        "https://api.github.com/repos/${PT_username}/${repo_name}/keys" \
        -H 'Content-Type: application/json' \
        -d "${json}" -o /tmp/curl.$$
  fi

  if  grep "HTTP/1.1 201 Created" /tmp/curl.$$
  then
    echo "Successfully added RSA deploy key"
    rm -f /tmp/curl.$$
  else
    echo "Failed to add RSA deploy key!"
    cat /tmp/curl.$$
    rm -f /tmp/curl.$$
    exit 1
  fi
}

create_file() {
  json='{
    "message": "Add file",
    "content": "'$2'"
  }'

  rm -f /tmp/curl.$$

  if [ "${PT_token}" != "" ] ; then
    curl -H "Authorization: token ${PT_token}" -i -s -X PUT \
        "https://api.github.com/repos/${PT_username}/${repo_name}/contents/$1" \
        -H 'Content-Type: application/json' \
        -d "${json}" -o /tmp/curl.$$
  else
    curl --user "${PT_username}":"${PT_password}" -i -s -X PUT \
        "https://api.github.com/repos/${PT_username}/${repo_name}/contents/$1" \
        -H 'Content-Type: application/json' \
        -d "${json}" -o /tmp/curl.$$
  fi

  if grep "HTTP/1.1 201 Created" /tmp/curl.$$
  then
    echo "Successfully created file ${1} in control repo"
    rm -f /tmp/curl.$$
  else
    echo "Failed to create file ${1} in control repo!"
    rm -f /tmp/curl.$$
    exit 1
  fi
}

#/////////////////////////////////////////////////////////////////////////////////////////////
# End of functions for use in script

# Main script execution
check_fork_repo
fork_repo $PT_username

if [ "${PT_token}" != "" ] ; then

  sha_id=$(curl -H "Authorization: token ${PT_token}" -X GET \
      "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/workshop_init" \
      | grep '"sha"' | awk '{split($0,a, "\""); print a[4]}')

else

  sha_id=$(curl --user "${PT_username}":"${PT_password}" -X GET \
     "https://api.github.com/repos/${PT_username}/${repo_name}/git/refs/heads/workshop_init" \
     | grep '"sha"' | awk '{split($0,a, "\""); print a[4]}')

fi

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
