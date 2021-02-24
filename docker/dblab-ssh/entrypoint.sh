#!/bin/bash

set -x

if [ -z "${DBLAB_SSH_KEY}" ] || [ "${DBLAB_SSH_KEY}" = "unset" ]; then
  echo "DBLAB_SSH_KEY not set"
  exit 1
fi

mkdir ~/.ssh
echo "${DBLAB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 0400 ~/.ssh/id_rsa
echo "${DBLAB_HOST_KEYS}" > ~/.ssh/known_hosts

ssh -f -N -L 2344:localhost:2345 -i ~/.ssh/id_rsa ${DBLAB_SSH_HOST}

dblab init --url http://127.0.0.1:2344 --token ${DBLAB_TOKEN} --environment-id ${DBLAB_ENVIRONMENT}

dblab_info=$(dblab clone create --id ${DBLAB_CLONE_ID} --username ${DBLAB_USER} --password ${DBLAB_PASSWORD})

if [ $? -ne 0 ]; then
  # Clone exists already - we need the port information to open the tunnel
  dblab_info=$(dblab clone status ${DBLAB_CLONE_ID})
fi

port=$(echo $dblab_info | jq -r .db.port)
id=$(echo $dblab_info | jq -r .id)

echo "Opening port forwarding on port ${port}"

# This blocks and opens port forwarding for Postgres
ssh -N -L :5432:localhost:$port -i ~/.ssh/id_rsa ${DBLAB_SSH_HOST}
