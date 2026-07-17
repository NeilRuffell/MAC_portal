FROM slaserx/stalker-portal:latest

RUN cp -a /var/www/html/stalker_portal/server/lib/core /tmp/base-server-lib-core

COPY . /var/www/html/stalker_portal
COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint

RUN rm -rf /var/www/html/stalker_portal/server/lib/core \
    && cp -a /tmp/base-server-lib-core /var/www/html/stalker_portal/server/lib/core \
    && chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
