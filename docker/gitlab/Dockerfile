FROM registry.gitlab.com/gitlab-org/gitlab-build-images:ruby-2.7.2-golang-1.14-git-2.29-lfs-2.9-chrome-85-node-12.18-yarn-1.22-postgresql-11-graphicsmagick-1.3.34

ARG GL_REPO=/repo/gitlab
ARG GL_SHA

ENV RAILS_ENV=test

RUN apt-get update; apt-get -y install iptables
RUN groupadd -r gitlab && useradd -r -g gitlab gitlab

USER gitlab
WORKDIR $GL_REPO

RUN mkdir -p $GL_REPO
RUN git clone --progress https://gitlab.com/gitlab-org/gitlab.git $GL_REPO
RUN bundle install
RUN git fetch origin $GL_SHA
RUN git reset --hard origin/${GL_SHA}
RUN bundle install

USER root
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh", "--"]
