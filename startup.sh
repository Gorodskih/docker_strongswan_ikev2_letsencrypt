#!/bin/sh -e

echo "Executing startup script..."

echo "Creating strongswan config..."

RIGHT_DNS=""
if [ -n "${VPN_DNS}" ]
then
	echo "Using DNS servers: ${VPN_DNS}."
	RIGHT_DNS="rightdns=${VPN_DNS}"
else
	echo "No DNS server is defined."
fi

CHARONDEBUG=""
if [ -n "${CHARON_DEBUG_PARAMS}" ]
then
	echo "Using charon debug parameters: ${CHARON_DEBUG_PARAMS}."
	CHARONDEBUG="charondebug=${CHARON_DEBUG_PARAMS}"
else
	echo "Using default charon debug parameters."
fi

echo "Using network: ${VPN_NETWORK:?VPN_NETWORK is not set or empty!}."
echo "Using IKE proposals: ${IKE_PROPOSALS:?IKE_PROPOSALS is not set or empty!}."
echo "Using ESP proposals: ${ESP_PROPOSALS:?ESP_PROPOSALS is not set or empty!}."

cat > /etc/ipsec.conf << EOF
config setup
	${CHARONDEBUG}
	uniqueids=no

conn ikev2-vpn
	auto=add
	compress=no
	type=tunnel
	keyexchange=ikev2
	fragmentation=yes
	forceencaps=yes
	dpdaction=clear
	dpddelay=300s
	rekey=no
	left=%any
	leftid=@${VPN_DOMAIN:?VPN_DOMAIN is not set or empty!}
	leftcert=fullchain.pem
	leftsendcert=always
	leftsubnet=0.0.0.0/0,::/0
	right=%any
	rightid=%any
	rightauth=eap-mschapv2
	rightsourceip=${VPN_NETWORK},fe80::0/16
	${RIGHT_DNS}
	rightsendcert=never
	eap_identity=%identity
	ike=${IKE_PROPOSALS}
	esp=${ESP_PROPOSALS}
EOF

cat > /etc/ipsec.secrets << EOF
: ECDSA privkey.pem
include /secrets/*.*
EOF

echo "Generating certificates using certbot..."

EMAIL_PARAM=" --register-unsafely-without-email"
if [ -n "${EMAIL}" ]
then
	echo "Using email for certbot: ${EMAIL}."
	EMAIL_PARAM=" -m ${EMAIL}"
else
	echo "Registering certificates unsafely without email."
fi


if [ -n "${CERTBOT_PARAMS}" ]
then
	echo "Using additional params for certbot: ${CERTBOT_PARAMS}."
else
	echo "Additional params for certbot are not defined."
fi

certbot certonly -n --standalone -d "${VPN_DOMAIN}"${EMAIL_PARAM} --agree-tos --keep-until-expiring --key-type ecdsa --logs-dir "/logs/letsencrypt" ${CERTBOT_PARAMS}

/copy_certs.sh

mkdir -p /logs/certbot/renew/deploy_hook

if [ -e /etc/letsencrypt/renewal-hooks/deploy/strongswan.sh ]
then
	echo "Certificate deploy hook already exists. Skipping."
else
	echo "Creating certificate deploy hook..."

cat > /etc/letsencrypt/renewal-hooks/deploy/strongswan.sh <<- 'EOF'
	LOG_PATH="/logs/certbot/renew/deploy_hook/$(date +"%Y-%m-%dT%H:%M:%S").log"

	/copy_certs.sh 2>&1 | tee -a "$LOG_PATH"

	echo "Reloading ipsec..." | tee -a "$LOG_PATH"
	ipsec reload 2>&1 | tee -a "$LOG_PATH"
EOF

	chmod +x /etc/letsencrypt/renewal-hooks/deploy/strongswan.sh
fi

echo "Configuring iptables..."
iptables -t nat -A POSTROUTING -s ${VPN_NETWORK} -o ${ETH_DEVICE} -m policy --dir out --pol ipsec -j ACCEPT
iptables -t nat -A POSTROUTING -s ${VPN_NETWORK} -o ${ETH_DEVICE} -j MASQUERADE

echo "Starting cron in background..."
crond -b -d 8

echo "Starting ipsec..."
exec ipsec start --nofork