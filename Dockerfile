FROM php:5.6-apache

# 1. Install system packages and PHP extension build dependencies
RUN apt-get update && apt-get install -y \
        libmcrypt-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libmemcached-dev \
        libxml2-dev \
        libicu-dev \
        default-libmysqlclient-dev \
        default-mysql-client \
        memcached \
        phing \
        unzip \
        cron \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install \
        mysql \
        mysqli \
        pdo_mysql \
        mcrypt \
        gd \
        soap \
        mbstring \
        zip \
        gettext \
        intl \
    && pecl install memcache \
    && echo "extension=memcache.so" > /usr/local/etc/php/conf.d/memcache.ini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy your repository as the sole source of truth
COPY . /var/www/html/stalker_portal/

# 3. Install IonCube 5.6 loader (backward compatible with PHP 5.3 encoded files)
#    Uses the loader bundled in deploy/src/ioncube - no internet required
RUN PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');") \
    && cp /var/www/html/stalker_portal/deploy/src/ioncube/64/ioncube_loader_lin_5.6.so "$PHP_EXT_DIR/" \
    && echo "zend_extension=${PHP_EXT_DIR}/ioncube_loader_lin_5.6.so" > /usr/local/etc/php/conf.d/00-ioncube.ini

# 4. Run Composer install using the bundled composer.phar to generate admin/vendor.
#    This produces a clean autoload_files.php with NO references to SlaSerX Ministra files.
#    IonCube is now active so it can decode encoded files during classmap scanning.
RUN cd /var/www/html/stalker_portal/deploy \
    && php composer/composer.phar install --no-dev --optimize-autoloader 2>&1 || true

# 5. Create case-insensitive symlinks for the SplClassLoader autoloader
RUN ln -sf lib /var/www/html/stalker_portal/server/Lib \
    && ln -sf core /var/www/html/stalker_portal/server/lib/Core

# 6. Configure Apache: listen on port 88, enable mod_rewrite, allow .htaccess overrides
RUN sed -i 's/Listen 80/Listen 88/' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:88>/' /etc/apache2/sites-enabled/000-default.conf \
    && a2enmod rewrite \
    && printf '\n<Directory /var/www/html/stalker_portal/>\n\tOptions -Indexes -MultiViews\n\tAllowOverride ALL\n\tRequire all granted\n</Directory>\n' \
       >> /etc/apache2/sites-enabled/000-default.conf

# 7. Pre-create directories required by Phing at container startup
RUN mkdir -p /var/www/html/stalker_portal/screenshots \
             /var/www/html/stalker_portal/misc/logos \
             /var/www/html/stalker_portal/misc/audio_covers

# 8. Fix permissions for the web server
RUN chown -R www-data:www-data /var/www/html/stalker_portal

# 9. Set up entrypoint
COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
RUN chmod +x /usr/local/bin/mac-portal-entrypoint

EXPOSE 88

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
