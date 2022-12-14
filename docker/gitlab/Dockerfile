FROM registry.gitlab.com/gitlab-org/gitlab-build-images:ruby-2.7.2-golang-1.14-git-2.29-lfs-2.9-chrome-85-node-12.18-yarn-1.22-postgresql-11-graphicsmagick-1.3.34

ARG GITLAB_PATH=/gitlab

ENV RAILS_ENV=test

RUN apt-get update; apt-get -y install iptables sudo jq
RUN groupadd -r gitlab && useradd -m -r -g gitlab gitlab
RUN mkdir -p $GITLAB_PATH
RUN chown gitlab:gitlab $GITLAB_PATH

USER gitlab
WORKDIR $GITLAB_PATH

ARG UPSTREAM_GIT_URL=http://gitlab.com/gitlab-org/gitlab.git
RUN git config --global user.email "gitlab-org/database-team@gitlab.com"
RUN git config --global user.name "GitLab Database Team"
RUN git config --global remote.origin.fetch '+refs/merge-requests/*:refs/remotes/origin/merge-requests/*'
RUN git clone --progress "$UPSTREAM_GIT_URL" "$GITLAB_PATH"
RUN bundle config set deployment 'true'
RUN bundle config set clean 'true'
RUN bundle config set jobs $(nproc)
RUN bundle config set path vendor
RUN bundle config set retry 5
RUN bundle install

ARG GITLAB_COMMIT_SHA
RUN git fetch origin; git checkout ${GITLAB_COMMIT_SHA}
RUN bundle install
RUN bundle check

# Codebase patching
USER gitlab
WORKDIR $GITLAB_PATH
COPY patches patches
RUN patches/apply.sh

COPY list_migrations.rb list_migrations.rb
COPY lib/migration_lister.rb lib/migration_lister.rb
COPY clone_details.rb clone_details.rb
COPY clone_details.yml clone_details.yml
COPY prepare.sh prepare.sh
COPY prepare_postgres.sql prepare_postgres.sql

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod uga+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh", "--"]
