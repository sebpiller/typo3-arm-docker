FROM debian:buster

LABEL arch="armhf|armv7|aarch64|amd64|i386"

MAINTAINER Sébastien Piller <me@sebpiller.ch>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        ca-certificates apt-utils vim zip unzip curl wget apache2 \
        php7.3 php7.3-mbstring php7.3-zip php7.3-xml mariadb-server && \
    wget --no-check-certificate -O composer-setup.php https://getcomposer.org/installer && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
	ln -sf /dev/stderr /var/log/apache2/error.log && \
	ln -sf /dev/stderr /var/log/mysql/error.log

EXPOSE 80 3306

CMD [ "/bin/sh", "-c", "service mysql start && service apache2 start && sleep infinity" ]