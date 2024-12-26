FROM alpine

RUN set -xe \
    && apk update && apk upgrade \
    && apk add --no-cache iptables strongswan \
    && apk add --no-cache certbot \
    && crontab -l | { cat; echo "*0 0,12 * * * certbot renew > /logs/certbot/renew/$(date +"%Y-%m-%dT%H:%M:%S").log 2>&1"; } | crontab -

COPY copy_certs.sh /copy_certs.sh
COPY entrypoint.sh /entrypoint.sh
COPY startup.sh /startup.sh

RUN chmod +x /copy_certs.sh \
    && chmod +x /entrypoint.sh \
    && chmod +x /startup.sh

VOLUME /etc/letsencrypt /secrets /logs

ENV VPN_NETWORK=10.10.10.0/24
ENV ETH_DEVICE=eth0
ENV VPN_DOMAIN=vpn.example.com
ENV EMAIL=
ENV VPN_DNS=
ENV CERTBOT_PARAMS=""
ENV CHARON_DEBUG_PARAMS=""
ENV IKE_PROPOSALS=""
ENV ESP_PROPOSALS=""

EXPOSE 500/udp 4500/udp 80/tcp

ENTRYPOINT ["/entrypoint.sh"]