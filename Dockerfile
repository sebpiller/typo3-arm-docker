FROM debian:buster

LABEL arch="armhf|armv7|aarch64|amd64|i386"

MAINTAINER Sébastien Piller <me@sebpiller.ch>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        ca-certificates vim zip unzip curl wget git apache2 imagemagick \
        php7.3 php7.3-mbstring php7.3-mysql php7.3-curl php7.3-zip php7.3-xml php7.3-gd php7.3-intl mariadb-server && \
    a2enmod alias authz_core autoindex deflate expires filter headers rewrite setenvif && \
    wget --no-check-certificate -O composer-setup.php https://getcomposer.org/installer && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm -rf /var/lib/apt/lists/*

# Disable default site by default
RUN a2dissite 000-default

COPY ./default-start.sh /default-start.sh
RUN chmod +x /default-start.sh

# forward request and error logs to docker log collector
#RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
#	ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log && \
#	ln -sf /dev/stdout /var/log/apache2/typo3.log && \
#	ln -sf /dev/stderr /var/log/apache2/error.log && \
#	ln -sf /dev/stderr /var/log/apache2/other_vhosts_error.log && \
#	ln -sf /dev/stderr /var/log/mysql/error.log && \
#	ln -sf /dev/stderr /var/log/apache2/typo3_error.log

EXPOSE 80 3306

CMD [ "/bin/sh", "-c", "/default-start.sh && sleep infinity" ]