FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install official Apache, PHP 7.0, all extensions, Node.js, and locales
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
    php7.0-intl \
    php7.0-tidy \
    php7.0-xsl \
    php-memcached \
    php-imagick \
    php-geoip \
    memcached \
    wget \
    unzip \
    curl \
    mysql-client \
    git \
    nodejs \
    npm \
    locales \
    && rm -rf /var/lib/apt/lists/*

# 2. Download and install the official IonCube Loader
RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xvzf ioncube_loaders_lin_x86-64.tar.gz \
    && cp ioncube/ioncube_loader_lin_7.0.so /usr/lib/php/20151012/ \
    && echo "zend_extension = /usr/lib/php/20151012/ioncube_loader_lin_7.0.so" > /etc/php/7.0/apache2/conf.d/00-ioncube.ini \
    && echo "zend_extension = /usr/lib/php/20151012/ioncube_loader_lin_7.0.so" > /etc/php/7.0/cli/conf.d/00-ioncube.ini \
    && rm -rf ioncube_loaders_lin_x86-64.tar.gz ioncube

# 3. Clean default web root and copy repository files
RUN rm -rf /var/www/html/*
COPY . /var/www/html/stalker_portal/

RUN mkdir -p /var/www/html/stalker_portal/screenshots \
             /var/www/html/stalker_portal/misc/logos \
             /var/www/html/stalker_portal/misc/audio_covers


# 4. Download and install a stable legacy Phing version (2.13.x/2.12.x) compatible with PHP 7.0
RUN bash -c 'for version in 2.13.0 2.12.0 2.11.0; do \
      echo "Trying legacy Phing version $version..."; \
      if wget -q -O /usr/local/bin/phing "https://www.phing.info/get/phing-$version.phar"; then \
        chmod +x /usr/local/bin/phing; \
        echo "Successfully installed Phing $version!"; \
        exit 0; \
      fi; \
    done; \
    echo "ERROR: Failed to download legacy Phing." && exit 1'

# 5. Enable Apache rewrite module and AllowOverride All for .htaccess routing
RUN a2enmod rewrite \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# 6. Enable PHP short_open_tag (required for Stalker Portal template files)
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/g" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/short_open_tag = Off/short_open_tag = On/g" /etc/php/7.0/cli/php.ini

# 7. Setup entrypoint
COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
RUN chmod +x /usr/local/bin/mac-portal-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
