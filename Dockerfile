FROM alpine

RUN set -xe \
    && apk update && apk upgrade \
    && apk add --no-cache iptables strongswan \
    && apk add --no-cache certbot \
    && crontab -l | { cat; echo "*0 0,12 * * * certbot renew > /last_cert_renew.log 2>&1"; } | crontab -

COPY copy_certs.sh /copy_certs.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /copy_certs.sh \
    && chmod +x /entrypoint.sh

VOLUME /etc/letsencrypt /secrets

ENV VPN_NETWORK=10.10.10.0/24
ENV ETH_DEVICE=eth0
ENV VPN_DNS=8.8.8.8,8.8.4.4
ENV VPN_DOMAIN=vpn.example.com
ENV E_MAIL=example@mail.com

EXPOSE 500/udp 4500/udp 80/tcp

ENTRYPOINT ["/entrypoint.sh"]