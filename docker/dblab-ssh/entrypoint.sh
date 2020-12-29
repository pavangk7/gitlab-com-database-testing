#!/bin/bash

set -e

mkdir ~/.ssh
echo "${DBLAB_SSH_KEY}" > ~/.ssh/id_rsa
echo "${DBLAB_HOST_KEYS}" > ~/.ssh/known_hosts

ssh -f -N -L 2344:localhost:2345 ${DBLAB_SSH_HOST} -i ~/.ssh/id_rsa

dblab init --url http://127.0.0.1:2344 --token ${DBLAB_TOKEN} --environment-id ${DBLAB_ENVIRONMENT}

dblab_info=$(dblab clone create --username ${DBLAB_USER} --password ${DBLAB_PASSWORD})

port=$(echo $dblab_info | jq -r .db.port)

# This blocks and opens port forwarding for Postgres
ssh -N -L 5432:localhost:$port ${DBLAB_SSH_HOST} -i ~/.ssh/id_rsa

