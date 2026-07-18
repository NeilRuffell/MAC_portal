FROM slaserx/stalker-portal:latest

COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
COPY c/tv.js /var/www/html/stalker_portal/c/tv.js
COPY c/template /var/www/html/stalker_portal/c/template

RUN chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
