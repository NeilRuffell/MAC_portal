FROM ghcr.io/neilruffell/stalker-portal-base:latest

# 1. Temporarily save SlaSerX's library and vendor folders
RUN bash -c ' \
    if [ -d /var/www/html/stalker_portal/server/Lib ]; then \
        mv /var/www/html/stalker_portal/server/Lib /tmp/base-server-lib; \
    elif [ -d /var/www/html/stalker_portal/server/lib ]; then \
        mv /var/www/html/stalker_portal/server/lib /tmp/base-server-lib; \
    fi; \
    if [ -d /var/www/html/stalker_portal/admin/vendor ]; then \
        mv /var/www/html/stalker_portal/admin/vendor /tmp/admin_vendor; \
    fi'

# 2. Wipe the old files completely so ONLY your code is used
RUN rm -rf /var/www/html/*

# 3. Copy your clean repository code
COPY . /var/www/html/stalker_portal/

# 4. Restore the dependencies, merging SlaSerX's library files (like funcs) without overwriting yours
RUN bash -c ' \
    if [ -d /tmp/base-server-lib ]; then \
        # Overwrite the core folder completely (as it must match the PHP 7.0 engine) \
        rm -rf /var/www/html/stalker_portal/server/lib/core; \
        if [ -d /tmp/base-server-lib/core ]; then \
            cp -a /tmp/base-server-lib/core /var/www/html/stalker_portal/server/lib/core; \
        fi; \
        # Merge all other directories (like funcs) without overwriting your custom files \
        cp -an /tmp/base-server-lib/* /var/www/html/stalker_portal/server/lib/; \
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
