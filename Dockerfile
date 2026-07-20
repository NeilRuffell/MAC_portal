FROM ghcr.io/neilruffell/stalker-portal-base:latest

COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
COPY docker/patch-m3u-tv-chno.php /usr/local/bin/patch-m3u-tv-chno.php
COPY c/tv.js /var/www/html/stalker_portal/c/tv.js
COPY c/epg.js /var/www/html/stalker_portal/c/epg.js
COPY c/player.js /var/www/html/stalker_portal/c/player.js
COPY c/template /var/www/html/stalker_portal/c/template

RUN chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
