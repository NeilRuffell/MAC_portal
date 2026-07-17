FROM slaserx/stalker-portal:latest

COPY docker/entrypoint.sh /usr/local/bin/mac-portal-entrypoint

RUN chmod +x /usr/local/bin/mac-portal-entrypoint

ENTRYPOINT ["/usr/local/bin/mac-portal-entrypoint"]
