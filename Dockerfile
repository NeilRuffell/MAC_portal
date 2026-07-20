FROM ghcr.io/neilruffell/stalker-portal-base:latest

COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
COPY docker/patch-m3u-tv-chno.php /usr/local/bin/patch-m3u-tv-chno.php

# Copy the entire repository to make it the absolute source of truth
COPY . /var/www/html/stalker_portal/

RUN chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
