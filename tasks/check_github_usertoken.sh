#!/bin/bash
curl -s -H "Authorization: token ${PT_token}" https://api.github.com/user | jq '.login' -r -e