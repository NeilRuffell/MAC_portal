FROM slaserx/stalker-portal:latest

COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint
COPY c/tv.js /var/www/html/stalker_portal/c/tv.js
COPY c/epg.js /var/www/html/stalker_portal/c/epg.js
COPY c/player.js /var/www/html/stalker_portal/c/player.js
COPY c/template /var/www/html/stalker_portal/c/template
COPY admin/src/Controller/TvChannelsController.php /var/www/html/stalker_portal/admin/src/Controller/TvChannelsController.php

RUN chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
