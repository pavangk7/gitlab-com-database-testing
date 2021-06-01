FROM ubuntu:20.04

RUN apt-get update; apt-get -y install curl jq openssh-client webfs \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY dblab_install.sh /dblab_install.sh
RUN bash /dblab_install.sh

ENV DBLAB_SSH_HOST=gldatabase@gitlab-joe-poc.postgres.ai
ENV DBLAB_HOST_KEYS=unset
ENV DBLAB_SSH_KEY=unset

ENV DBLAB_USER=unset
ENV DBLAB_PASSWORD=unset
ENV DBLAB_ENVIRONMENT=gitlab-production-tunnel
ENV DBLAB_TOKEN=unset
ENV DBLAB_CLONE_ID=unset
ENV DBLAB_API_PORT=unset

COPY entrypoint.sh /entrypoint.sh
RUN chmod uga+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh", "--"]

RUN groupadd -r dblab && useradd -m -r -g dblab dblab
USER dblab

EXPOSE 5432 8000