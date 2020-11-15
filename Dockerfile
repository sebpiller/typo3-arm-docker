FROM debian:buster

LABEL arch="armhf|armv7|aarch64|amd64|i386"

MAINTAINER Sébastien Piller <me@sebpiller.ch>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl apache2 php mariadb-server && \
    curl -s https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

CMD [ "sleep", "infinity" ]