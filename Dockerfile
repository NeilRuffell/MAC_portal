FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apache2 \
    software-properties-common \
    libapache2-mod-php7.0 \
    php7.0 \
    php7.0-mysql \
    php7.0-mcrypt \
    php7.0-gd \
    php7.0-curl \
    php7.0-xml \
    php7.0-mbstring \
    php7.0-zip \
    php7.0-soap \
    memcached \
    php-memcached \
    wget \
    unzip \
    curl \
    mysql-client \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xvzf ioncube_loaders_lin_x86-64.tar.gz \
    && cp ioncube/ioncube_loader_lin_7.0.so /usr/lib/php/20151012/ \
    && echo "zend_extension = /usr/lib/php/20151012/ioncube_loader_lin_7.0.so" > /etc/php/7.0/apache2/conf.d/00-ioncube.ini \
    && echo "zend_extension = /usr/lib/php/20151012/ioncube_loader_lin_7.0.so" > /etc/php/7.0/cli/conf.d/00-ioncube.ini \
    && rm -rf ioncube_loaders_lin_x86-64.tar.gz ioncube

RUN a2enmod rewrite

RUN rm -rf /var/www/html/*
COPY . /var/www/html/stalker_portal/

COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
RUN chmod +x /usr/local/bin/mac-portal-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
