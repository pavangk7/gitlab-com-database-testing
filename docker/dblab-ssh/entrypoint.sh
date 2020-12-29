#!/usr/bin/env sh

mkdir ~/.ssh
echo "${DBLAB_SSH_KEY}" > ~/.ssh/id_rsa
echo "${DBLAB_HOST_KEYS}" > ~/.ssh/known_hosts

ssh -f -N -L 2344:localhost:2345 ${DBLAB_SSH_HOST} -i ~/.ssh/id_rsa

dblab init --url http://127.0.0.1:2344 --token ${DBLAB_TOKEN} --environment-id ${DBLAB_ENVIRONMENT}

sh -c "$@"
