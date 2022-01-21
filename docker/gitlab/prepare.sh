#!/bin/bash

cp config/gitlab.yml.example config/gitlab.yml
sed -i 's/bin_path: \/usr\/bin\/git/bin_path: \/usr\/local\/bin\/git/' config/gitlab.yml

cat > config/database.yml <<-EOF
test: &test
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_dblab
  username: ${DBLAB_USER}
  password: ${DBLAB_PASSWORD}
  host: postgres
  prepared_statements: false
  variables:
    statement_timeout: 120s
EOF

if test "$VALIDATION_PIPELINE"; then
  echo "Applying test patch"
  git am < /gitlab/patches/testing/New-Table-Migration.patch
  git am < /gitlab/patches/testing/Drop-table-in-post-migration.patch
  git am < /gitlab/patches/testing/Exception-Raised-in-Migration.patch
  git am < /gitlab/patches/testing/Add-a-migration-that-takes-five-seconds.patch
  git am < /gitlab/patches/testing/Migration-inheriting-Gitlab-Database-Migration.patch
fi

### REDIS

cp config/cable.yml.example config/cable.yml
sed -i 's|url:.*$|url: redis://redis:6379|g' config/cable.yml

cp config/resque.yml.example config/resque.yml
sed -i 's|url:.*$|url: redis://redis:6379|g' config/resque.yml

cp config/resque.yml.example config/redis.cache.yml
sed -i 's|url:.*$|url: redis://redis:6379/10|g' config/redis.cache.yml

cp config/resque.yml.example config/redis.queues.yml
sed -i 's|url:.*$|url: redis://redis:6379/11|g' config/redis.queues.yml

cp config/resque.yml.example config/redis.shared_state.yml
sed -i 's|url:.*$|url: redis://redis:6379/12|g' config/redis.shared_state.yml

### Preparing PG cluster

# It can take a long time for the database to be ready for connections
PGPASSWORD="${DBLAB_PASSWORD}" pg_isready -h postgres -U "${DBLAB_USER}" --dbname=gitlabhq_dblab --timeout=300
PGPASSWORD="${DBLAB_PASSWORD}" psql -h postgres -U "${DBLAB_USER}" gitlabhq_dblab < /gitlab/prepare_postgres.sql

