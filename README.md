# docker_strongswan_ikev2_letsencrypt

### Simple Docker container to start your own IKEv2 VPN server using Let's Encrypt certificate with auto renewal

#### Installation steps:
1. Create empty folder on your server for passwords file (e.g. **/secrets**)
2. Create text file in this folder aith any name (*.*) (e.g. **/secrets/ipsec.secrets**)
3. Add following line for each VPN user:
`username : EAP "password"`
4. Save and close the file.
5. Copy file [docker-compose.yml](https://github.com/Gorodskih/docker_strongswan_ikev2_letsencrypt/blob/main/docker-compose.yml) to any folder
6. Edit **docker-compose.yml**:
    1. Line **15**: change first **/secrets** to the created folder with passwords file. Do not change right side (**/secrets:ro**). (e.g. `- /foo/bar/secrets:/secrets:ro`)
    2. Line **20**: change **vpn.example.com** to your domain name (it should be already configured to point at your server's IP address).
    3. Line **21**: change **example@mail.com** to your mail for Let's Encrypt purposes.
7. Save and close **docker-compose.yml**.
8. Install *Docker* and *Docker Compose* if not installed.
9. Check that ports **500**, **4500**, and **80** are opened.
10. cd to the folder where **docker-compose.yml** is located.
11. Start container using Docker Compose command [**up**](https://docs.docker.com/engine/reference/commandline/compose_up/). It may depend on your Docker Compose installation. (e.g. `sudo docker compose up`, `sudo docker-compose up`).
12. Check logs that Let's Encrypt certificate is successfully obtained. And there is no errors.
13. Try to connect to your VPN.
14. If everything is fine, press Ctrl+C to stop container.
15. Start container in detached mode as backgroud service using flag `-d`: `sudo docker compose up -d`
16. Now server is running on backgroud and automatically restarted.

Let's Encrypt certificates should be renewed every 90 days. Cron task checks for expiration every 12 hours as recommended by Let's Encrypt.
Renewal logs should be in the file **/last_cert_renew.log**

#### Environment variables description:
1. **VPN_NETWORK** (*required*)
   
   Network with a prefix for VPN clients.
2. **ETH_DEVICE** (*required*)
   
   Network device name for iptables configuration.
3. **VPN_DOMAIN** (*required*)
   
   Domain name for certificate obtaining.
4. **EMAIL** (*not required*)
   
   Email for certificate registration. Will be used by "Let's encrypt" for expiration notifications.
5. **VPN_DNS** (*not required*)
   
   DNS servers for VPN clients divided by comma. If not set then DNS servers will not be specified.
6. **CERTBOT_PARAMS** (*not required*)
   
   Additional command line parameters for **certbot** (https://eff-certbot.readthedocs.io/en/stable/using.html)
7. **CHARON_DEBUG_PARAMS** (*not required*)
   
   Debug log levels for **charon** (https://docs.strongswan.org/docs/latest/config/logging.html)
8. **IKE_PROPOSALS** (*required*)
   
   IKE Cipher Suites list divided by comma. (https://docs.strongswan.org/docs/latest/config/proposals.html)
9. **ESP_PROPOSALS** (*required*)
   
   ESP Cipher Suites list divided by comma. (https://docs.strongswan.org/docs/latest/config/proposals.html)
