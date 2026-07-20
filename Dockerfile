FROM ghcr.io/neilruffell/stalker-portal-base:latest

# 1. Temporarily save the vendor dependencies from the base image
RUN mv /var/www/html/stalker_portal/admin/vendor /tmp/admin_vendor

# 2. Wipe the old stalker_portal files completely so ONLY your code is used
RUN rm -rf /var/www/html/stalker_portal/*

# 3. Copy your clean repository code
COPY . /var/www/html/stalker_portal/

# 4. Restore the vendor dependencies
RUN rm -rf /var/www/html/stalker_portal/admin/vendor \
    && mv /tmp/admin_vendor /var/www/html/stalker_portal/admin/vendor

# 5. Fix permissions for the web server user
RUN chown -R www-data:www-data /var/www/html/stalker_portal

# 6. Set up entrypoint
COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
RUN chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
