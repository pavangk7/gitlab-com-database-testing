FROM registry.gitlab.com/gitlab-org/gitlab-build-images:ruby-2.7.2-golang-1.14-git-2.29-lfs-2.9-chrome-85-node-12.18-yarn-1.22-postgresql-11-graphicsmagick-1.3.34

ARG GITLAB_PATH=/gitlab

ENV RAILS_ENV=test

RUN apt-get update; apt-get -y install iptables sudo jq
RUN groupadd -r gitlab && useradd -m -r -g gitlab gitlab
RUN mkdir -p $GITLAB_PATH
RUN chown gitlab:gitlab $GITLAB_PATH

USER gitlab
WORKDIR $GITLAB_PATH

RUN git config --global user.email "gitlab-org/database-team@gitlab.com"
RUN git config --global user.name "GitLab Database Team"
RUN git clone --progress https://gitlab.com/gitlab-org/gitlab.git $GITLAB_PATH
RUN bundle config set deployment 'true'
RUN bundle config set clean 'true'
RUN bundle config set jobs $(nproc)
RUN bundle config set path vendor
RUN bundle config set retry 3
RUN bundle install

ARG GITLAB_COMMIT_SHA
RUN git fetch origin; git checkout ${GITLAB_COMMIT_SHA}
RUN bundle install
RUN bundle check

# Codebase patching
USER gitlab
WORKDIR $GITLAB_PATH
COPY patches patches
RUN git am < patches/0001-Disable-AssetProxyFilter-initializer.patch
RUN git am < patches/0002-Disable-automatic-schema-dumping-after-migration.patch

COPY prepare.sh prepare.sh

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod uga+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh", "--"]
