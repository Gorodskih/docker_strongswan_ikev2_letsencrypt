#!/bin/sh -e

echo "Creating strongswan config..."

cat > /etc/ipsec.conf << EOF
config setup
	charondebug="ike 1, knl 1, cfg 0"
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
	leftid=@${VPN_DOMAIN}
	leftcert=fullchain.pem
	leftsendcert=always
	leftsubnet=0.0.0.0/0,::/0
	right=%any
	rightid=%any
	rightauth=eap-mschapv2
	rightsourceip=${VPN_NETWORK},fe80::0/16
	rightdns=${VPN_DNS}
	rightsendcert=never
	eap_identity=%identity
	ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024
	esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1
EOF

cat > /etc/ipsec.secrets << EOF
: ECDSA privkey.pem
include /secrets/*.*
EOF

echo "Generating certificates using certbot..."
certbot certonly -n --standalone -d "${VPN_DOMAIN}" -m "${E_MAIL}" --agree-tos --keep-until-expiring --key-type ecdsa

/copy_certs.sh

if [ -e /etc/letsencrypt/renewal-hooks/deploy/strongswan.sh ]
then
	echo "Certificate deploy hook already exists. Skipping."
else
	echo "Creating certificate deploy hook..."

cat > /etc/letsencrypt/renewal-hooks/deploy/strongswan.sh <<- EOF
	/copy_certs.sh

	echo "Purging certificates by ipsec..."
	ipsec purgecerts
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