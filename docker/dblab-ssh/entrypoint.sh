#!/bin/bash

set -e

if [ -z "${DBLAB_SSH_KEY}" ] || [ "${DBLAB_SSH_KEY}" = "unset" ]; then
  echo "DBLAB_SSH_KEY not set"
  exit 1
fi

mkdir ~/.ssh
echo "${DBLAB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 0400 ~/.ssh/id_rsa
echo "${DBLAB_HOST_KEYS}" > ~/.ssh/known_hosts

ssh -f -N -L 2345:localhost:"${DBLAB_API_PORT}" -i ~/.ssh/id_rsa "${DBLAB_SSH_HOST}"

dblab init --url http://127.0.0.1:2345 --token "${DBLAB_TOKEN}" --environment-id "${DBLAB_ENVIRONMENT}"

dblab_info=$(dblab clone create --id "${DBLAB_CLONE_ID}" --username "${DBLAB_USER}" --password "${DBLAB_PASSWORD}")

port=$(echo "$dblab_info" | jq -r .db.port)
id=$(echo "$dblab_info" | jq -r .id)
createdAt=$(echo "$dblab_info" | jq -r .createdAt)
cloneStateTimestamp=$(echo "$dblab_info" | jq -r .snapshot.dataStateAt)
maxIdleMinutes=$(echo "$dblab_info" | jq -r .metadata.maxIdleMinutes)

echo "Opening port forwarding on port ${port}"

mkdir -p ~/webInfo
cat <<INFO > ~/webInfo/info.json
{
  "createdAt": "$createdAt",
  "cloneStateTimestamp": "$cloneStateTimestamp",
  "cloneId": "$id",
  "maxIdleMinutes": $maxIdleMinutes
}
INFO
webfsd -p 8000 -r ~/webInfo

echo "Started server with clone info on port 8000"

# This blocks and opens port forwarding for Postgres
ssh -N -L ":5432:localhost:$port" -i ~/.ssh/id_rsa "${DBLAB_SSH_HOST}"
