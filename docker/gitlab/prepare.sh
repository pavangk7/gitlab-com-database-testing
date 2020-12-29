#!/bin/bash

cp config/gitlab.yml.example config/gitlab.yml
sed -i 's/bin_path: \/usr\/bin\/git/bin_path: \/usr\/local\/bin\/git/' config/gitlab.yml

cp config/database.yml.postgresql config/database.yml

# Set user to a non-superuser to ensure we test permissions
sed -i 's/username: root/username: gitlab/g' config/database.yml

sed -i 's/localhost/postgres/g' config/database.yml
sed -i "s/username: postgres/username: ${DBLAB_USER}/g" config/database.yml
sed -i "s/password:.*/password: ${DBLAB_PASSWORD}/g" config/database.yml

cp config/cable.yml.example config/cable.yml
sed -i 's|url:.*$|url: redis://redis:6379|g' config/cable.yml

cp config/resque.yml.example config/resque.yml
sed -i 's|url:.*$|url: redis://redis:6379|g' config/resque.yml

cp config/redis.cache.yml.example config/redis.cache.yml
sed -i 's|url:.*$|url: redis://redis:6379/10|g' config/redis.cache.yml

cp config/redis.queues.yml.example config/redis.queues.yml
sed -i 's|url:.*$|url: redis://redis:6379/11|g' config/redis.queues.yml

cp config/redis.shared_state.yml.example config/redis.shared_state.yml
sed -i 's|url:.*$|url: redis://redis:6379/12|g' config/redis.shared_state.yml
