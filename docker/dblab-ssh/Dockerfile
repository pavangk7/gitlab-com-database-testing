FROM ubuntu:20.04

RUN apt-get update; apt-get -y install curl

COPY dblab_install.sh /dblab_install.sh
RUN bash /dblab_install.sh

ENV DBLAB_SSH_HOST=gldatabase@gitlab-joe-poc.postgres.ai
ENV DBLAB_ENVIRONMENT=gitlab-production-tunnel
ENV DBLAB_TOKEN=unset
ENV DBLAB_SSH_KEY=unset

RUN groupadd -r dblab && useradd -r -g dblab dblab
USER dblab
