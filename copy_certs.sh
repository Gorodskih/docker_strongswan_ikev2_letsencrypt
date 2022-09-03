#!/bin/sh -e

echo "Copying certificates..."
cp -v "/etc/letsencrypt/live/${VPN_DOMAIN}/privkey.pem" "/etc/ipsec.d/private/privkey.pem"
cp -v "/etc/letsencrypt/live/${VPN_DOMAIN}/fullchain.pem" "/etc/ipsec.d/certs/fullchain.pem"
cp -v "/etc/letsencrypt/live/${VPN_DOMAIN}/chain.pem" "/etc/ipsec.d/cacerts/chain.pem"


#Loading fullchain.pem on connection on Alpine using symlink doesn't work (Permission denied)