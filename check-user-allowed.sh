#!/bin/bash

set -e

allowed_users=$(curl "https://ops.gitlab.net/api/v4/projects/${CI_PROJECT_ID}/members/all?private_token=${PROJECT_API_TOKEN}" | jq -r '.[] | .username ')
current_user="${TRIGGERED_USER_LOGIN:-$GITLAB_USER_LOGIN}"

if ! echo "$allowed_users" | grep -q "^${current_user}$"; then
  echo "User is not part of the allow-list: ${current_user}"
  echo "Allowed users are:"
  echo $allowed_users

  exit -1
fi
