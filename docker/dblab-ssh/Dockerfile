FROM ubuntu:20.04

RUN apt-get update; apt-get -y install curl openssh-client

COPY dblab_install.sh /dblab_install.sh
RUN bash /dblab_install.sh

ENV DBLAB_SSH_HOST=gldatabase@gitlab-joe-poc.postgres.ai
ENV DBLAB_ENVIRONMENT=gitlab-production-tunnel
ENV DBLAB_TOKEN=unset
ENV DBLAB_SSH_KEY=unset

COPY entrypoint.sh /entrypoint.sh
RUN chmod uga+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh", "--"]

RUN groupadd -r dblab && useradd -m -r -g dblab dblab
USER dblab

EXPOSE 5432