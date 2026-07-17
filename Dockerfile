FROM slaserx/stalker-portal:latest

COPY c /opt/mac_portal/c
COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint

RUN chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
