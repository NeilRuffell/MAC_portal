FROM ghcr.io/neilruffell/stalker-portal-base:latest

# 1. Temporarily save the core files and vendor dependencies if they exist
RUN bash -c ' \
    if [ -d /var/www/html/stalker_portal/server/lib/core ]; then \
        mv /var/www/html/stalker_portal/server/lib/core /tmp/base-server-lib-core; \
    fi; \
    if [ -d /var/www/html/stalker_portal/admin/vendor ]; then \
        mv /var/www/html/stalker_portal/admin/vendor /tmp/admin_vendor; \
    fi'

# 2. Wipe the old stalker_portal files completely so ONLY your code is used
RUN rm -rf /var/www/html/stalker_portal/*

# 3. Copy your clean repository code
COPY . /var/www/html/stalker_portal/

# 4. Restore the saved core files and vendor dependencies
RUN bash -c ' \
    if [ -d /tmp/base-server-lib-core ]; then \
        rm -rf /var/www/html/stalker_portal/server/lib/core; \
        mv /tmp/base-server-lib-core /var/www/html/stalker_portal/server/lib/core; \
    fi; \
    if [ -d /tmp/admin_vendor ]; then \
        rm -rf /var/www/html/stalker_portal/admin/vendor; \
        mv /tmp/admin_vendor /var/www/html/stalker_portal/admin/vendor; \
    fi'

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
