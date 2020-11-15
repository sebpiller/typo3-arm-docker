FROM debian:buster

LABEL arch="armhf|armv7|aarch64|amd64|i386"

MAINTAINER Sébastien Piller <me@sebpiller.ch>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl wget apache2 php mariadb-server git-all && \
    wget -O composer-setup.php https://getcomposer.org/installer && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# cd /sites && composer -n create-project typo3/cms-base-distribution mysuperproject

CMD [ "sleep", "infinity" ]