#!/bin/bash

cp config/gitlab.yml.example config/gitlab.yml
sed -i 's/bin_path: \/usr\/bin\/git/bin_path: \/usr\/local\/bin\/git/' config/gitlab.yml

echo 'using decomposed database.yml'

cat > config/database.yml <<-EOF
test: &test
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_dblab
    username: gitlab
    password: ${DBLAB_PASSWORD}
    host: postgres-main
    prepared_statements: false
    variables:
      statement_timeout: 120s
  ci:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_dblab
    username: gitlab
    password: ${DBLAB_PASSWORD}
    host: postgres-ci
    prepared_statements: false
    variables:
      statement_timeout: 120s
EOF

if test "$VALIDATION_PIPELINE"; then
  echo "Applying test patches"
  /gitlab/patches/testing/apply.sh
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

# These will never have spaces, so it's safe to split this way
for db_host in $(echo "$ALL_DB_HOSTS" | tr ',' '\n'); do
  if timeout 60s bash -c "until pg_isready --quiet -h ${db_host} -U ${DBLAB_USER} --dbname=gitlabhq_dblab; do sleep 1; done"; then
    PGPASSWORD="${DBLAB_PASSWORD}" psql -h "${db_host}" -U "${DBLAB_USER}" gitlabhq_dblab < /gitlab/prepare_postgres.sql
  else
    echo "Unable to connect to database lab psql for optional configuration of ${db_host}"
  fi

  # Reset `gitlab` user password - this is the PG user we're going to use later to execute migrations
  # We re-use $DBLAB_PASSWORD variable here
  if timeout 60s bash -c "until pg_isready --quiet -h ${db_host} -U ${DBLAB_USER} --dbname=gitlabhq_dblab; do sleep 1; done"; then
    echo "ALTER USER gitlab PASSWORD '${DBLAB_PASSWORD}'; GRANT EXECUTE ON FUNCTION pg_stat_statements_reset() to gitlab;" | PGPASSWORD="${DBLAB_PASSWORD}" psql -h "${db_host}" -U "${DBLAB_USER}" gitlabhq_dblab
  else
    echo "Unable to connect to database lab psql for mandatory user configuration on ${db_host}"
    exit 1
  fi
done

