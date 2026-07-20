FROM ghcr.io/neilruffell/stalker-portal-base:latest

# 1. Temporarily save the core files (checking both Lib and lib casing) and vendor dependencies
RUN bash -c ' \
    if [ -d /var/www/html/stalker_portal/server/Lib/core ]; then \
        mv /var/www/html/stalker_portal/server/Lib/core /tmp/base-server-lib-core; \
    elif [ -d /var/www/html/stalker_portal/server/lib/core ]; then \
        mv /var/www/html/stalker_portal/server/lib/core /tmp/base-server-lib-core; \
    fi; \
    if [ -d /var/www/html/stalker_portal/admin/vendor ]; then \
        mv /var/www/html/stalker_portal/admin/vendor /tmp/admin_vendor; \
    fi'

# 2. Wipe the old files completely so ONLY your code is used
RUN rm -rf /var/www/html/*

# 3. Copy your clean repository code
COPY . /var/www/html/stalker_portal/

# 4. Restore the saved core files and vendor dependencies to your portal folder
RUN bash -c ' \
    if [ -d /tmp/base-server-lib-core ]; then \
        rm -rf /var/www/html/stalker_portal/server/lib/core; \
        mv /tmp/base-server-lib-core /var/www/html/stalker_portal/server/lib/core; \
    fi; \
    if [ -d /tmp/admin_vendor ]; then \
        rm -rf /var/www/html/stalker_portal/admin/vendor; \
        mv /tmp/admin_vendor /var/www/html/stalker_portal/admin/vendor; \
    fi'

# 5. Create Lib symlink for case-insensitive autoloader compatibility
RUN ln -sf lib /var/www/html/stalker_portal/server/Lib

# 6. Pre-create directories required by Phing
RUN mkdir -p /var/www/html/stalker_portal/screenshots \
             /var/www/html/stalker_portal/misc/logos \
             /var/www/html/stalker_portal/misc/audio_covers

# 7. Fix permissions for the web server user
RUN chown -R www-data:www-data /var/www/html/stalker_portal

# 8. Set up entrypoint
COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
RUN chmod +x /usr/local/bin/mac-portal-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
