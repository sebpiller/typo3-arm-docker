FROM debian:buster

LABEL arch="armhf|armv7|aarch64|amd64|i386"

MAINTAINER Sébastien Piller <me@sebpiller.ch>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends apt-utils zip unzip curl wget apache2 php7.3 php7.3-mbstring php7.3-zip php7.3-xml mariadb-server && \
    wget --no-check-certificate -O composer-setup.php https://getcomposer.org/installer && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# cd /sites && composer -n create-project typo3/cms-base-distribution mysuperproject

CMD [ "sleep", "infinity" ]