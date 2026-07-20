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

# 4. Download, verify, and install a PHP 7.0 compatible Phing version
RUN bash -c 'for version in 2.16.4 2.16.3 2.16.2 2.16.1 2.16.0 2.15.2; do \
      echo "Trying Phing version $version..."; \
      if wget -q -O phing.phar "https://github.com/phingofficial/phing/releases/download/$version/phing-$version.phar" || \
         wget -q -O phing.phar "https://www.phing.info/get/phing-$version.phar"; then \
        if php phing.phar -version > /dev/null 2>&1; then \
          echo "Successfully verified Phing version $version!"; \
          mv phing.phar /usr/local/bin/phing; \
          chmod +x /usr/local/bin/phing; \
          exit 0; \
        else \
          echo "Phing version $version is not compatible with PHP 7.0."; \
          rm -f phing.phar; \
        fi; \
      else \
        echo "Phing version $version download failed."; \
        rm -f phing.phar; \
      fi; \
    done; \
    echo "ERROR: No compatible Phing version could be downloaded and verified."; \
    exit 1'

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
