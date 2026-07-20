FROM ghcr.io/neilruffell/stalker-portal-base:latest

# 1. Temporarily save the PHP 7.0 compatible IonCube core files and vendor dependencies
RUN mv /var/www/html/stalker_portal/server/lib/core /tmp/base-server-lib-core \
    && mv /var/www/html/stalker_portal/admin/vendor /tmp/admin_vendor

# 2. Wipe the old stalker_portal files completely so ONLY your code is used
RUN rm -rf /var/www/html/stalker_portal/*

# 3. Copy your clean repository code
COPY . /var/www/html/stalker_portal/

# 4. Restore the IonCube core files and vendor dependencies
RUN rm -rf /var/www/html/stalker_portal/server/lib/core \
    && mv /tmp/base-server-lib-core /var/www/html/stalker_portal/server/lib/core \
    && rm -rf /var/www/html/stalker_portal/admin/vendor \
    && mv /tmp/admin_vendor /var/www/html/stalker_portal/admin/vendor

# 5. Pre-create directories required by Phing
RUN mkdir -p /var/www/html/stalker_portal/screenshots \
             /var/www/html/stalker_portal/misc/logos \
             /var/www/html/stalker_portal/misc/audio_covers

# 6. Fix permissions for the web server user
RUN chown -R www-data:www-data /var/www/html/stalker_portal

# 7. Set up entrypoint
COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
RUN chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
