FROM slaserx/stalker-portal@sha256:becec7048d39159a0a3ce536aedfa948dba1531b4b1cbc7f80c1a18f9f168ce7

# 1. Save the runtime dependencies we need from the base image:
#    - entire admin dir (for functions.php, vendor, config/, etc.)
#    - server/Lib/funcs (helper functions)
RUN bash -c ' \
    mkdir -p /tmp/base; \
    if [ -d /var/www/html/stalker_portal/admin ]; then \
        cp -a /var/www/html/stalker_portal/admin /tmp/base/admin; \
    fi; \
    if [ -d /var/www/html/stalker_portal/server/Lib/funcs ]; then \
        cp -a /var/www/html/stalker_portal/server/Lib/funcs /tmp/base/server-funcs; \
    fi'

# 2. Wipe the base image portal files
RUN rm -rf /var/www/html/*

# 3. Copy YOUR repository as the source of truth
COPY . /var/www/html/stalker_portal/

# 4. Restore runtime dependencies back into your repo tree
#    cp -n (no-overwrite) means YOUR repo files always win
RUN bash -c ' \
    if [ -d /tmp/base/admin ]; then \
        cp -an /tmp/base/admin/. /var/www/html/stalker_portal/admin/; \
    fi; \
    if [ -d /tmp/base/server-funcs ]; then \
        mkdir -p /var/www/html/stalker_portal/server/lib/funcs; \
        cp -an /tmp/base/server-funcs/. /var/www/html/stalker_portal/server/lib/funcs/; \
    fi'

# 5. Create case-insensitive symlinks for the autoloader
RUN ln -sf lib /var/www/html/stalker_portal/server/Lib \
    && ln -sf core /var/www/html/stalker_portal/server/lib/Core

# 6. Pre-create directories required by Phing
RUN mkdir -p /var/www/html/stalker_portal/screenshots \
             /var/www/html/stalker_portal/misc/logos \
             /var/www/html/stalker_portal/misc/audio_covers

# 7. Fix permissions
RUN chown -R www-data:www-data /var/www/html/stalker_portal

# 8. Set up entrypoint
COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
RUN chmod +x /usr/local/bin/mac-portal-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
