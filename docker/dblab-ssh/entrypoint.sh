#!/bin/bash

set -e

mkdir ~/.ssh
echo "${DBLAB_SSH_KEY}" > ~/.ssh/id_rsa
echo "${DBLAB_HOST_KEYS}" > ~/.ssh/known_hosts

cat ~/.ssh/known_hosts

env

echo "DBLABS: ${DBLAB_SSH_HOST}"

ssh -f -N -L 2344:localhost:2345 -i ~/.ssh/id_rsa ${DBLAB_SSH_HOST}

dblab init --url http://127.0.0.1:2344 --token ${DBLAB_TOKEN} --environment-id ${DBLAB_ENVIRONMENT}

dblab instance status

dblab_info=$(dblab clone create --username ${DBLAB_USER} --password ${DBLAB_PASSWORD})

port=$(echo $dblab_info | jq -r .db.port)

echo $dblab_info
echo
echo "Opening port forwarding on port ${port}"

# This blocks and opens port forwarding for Postgres
ssh -N -L 5432:localhost:$port -i ~/.ssh/id_rsa ${DBLAB_SSH_HOST}

