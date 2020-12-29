#!/bin/bash

set -e

mkdir ~/.ssh
echo "${DBLAB_SSH_KEY}" > ~/.ssh/id_rsa
chmod 0400 ~/.ssh/id_rsa
echo "${DBLAB_HOST_KEYS}" > ~/.ssh/known_hosts

ssh -f -N -L 2344:localhost:2345 -i ~/.ssh/id_rsa ${DBLAB_SSH_HOST}

dblab init --url http://127.0.0.1:2344 --token ${DBLAB_TOKEN} --environment-id ${DBLAB_ENVIRONMENT}

dblab_info=$(dblab clone create --username ${DBLAB_USER} --password ${DBLAB_PASSWORD})

port=$(echo $dblab_info | jq -r .db.port)
id=$(echo $dblab_info | jq -r .id)

dblab_cleanup() {
  echo "Cleaning up and destroying dblab clone $id"
  dblab clone destroy $id
}

trap dblab_cleanup TERM INT EXIT

echo "Opening port forwarding on port ${port}"

# This blocks and opens port forwarding for Postgres
ssh -N -L :5432:localhost:$port -i ~/.ssh/id_rsa ${DBLAB_SSH_HOST}
