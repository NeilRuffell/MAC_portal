FROM slaserx/stalker-portal:latest

COPY . /opt/mac_portal

RUN chmod +x /opt/mac_portal/docker/entrypoint.sh

ENTRYPOINT ["/opt/mac_portal/docker/entrypoint.sh"]
