FROM ubuntu:20.04

RUN apt-get update; apt-get -y install curl openssh-client

COPY dblab_install.sh /dblab_install.sh
RUN bash /dblab_install.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod uga+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh", "--"]

RUN groupadd -r dblab && useradd -m -r -g dblab dblab
USER dblab

EXPOSE 5432