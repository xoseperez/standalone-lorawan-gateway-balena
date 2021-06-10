#!/bin/sh

# Get configuration
CONFIG_FILE=/home/thethings/ttn-lw-stack-docker.yml
CERTIFICATES_FOLDER=/srv/certificates
CERTIFICATES_FOLDER_ESC=$(echo "${CERTIFICATES_FOLDER}" | sed 's/\//\\\//g')
SERVER_NAME=${SERVER_NAME:-The Things Stack}
EMAIL=${EMAIL:-noreply@thethings.example.com}
DOMAIN=${DOMAIN:-thethings.example.com}
if [ ! $SMTP_HOST == "" ]; then
    MAIL_PROVIDER="smtp"
else
    MAIL_PROVIDER="sendgrid"
fi
BLOCK_KEY=$(openssl rand -hex 32)
HASH_KEY=$(openssl rand -hex 64)
IP_ETH0=$(ip a s eth0 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)
IP_WLAN0=$(ip a s wlan0 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)
[ "$IP_WLAN0" == "" ] && IP_WLAN0=$IP_ETH0
[ "$IP_ETH0" == "" ] && IP_ETH0=$IP_WLAN0

# Build config file
cp ${CONFIG_FILE}.template ${CONFIG_FILE}
sed -i -e "s/{{server_name}}/${SERVER_NAME}/g" $CONFIG_FILE
sed -i -e "s/{{email}}/${EMAIL}/g" $CONFIG_FILE
sed -i -e "s/{{domain}}/${DOMAIN}/g" $CONFIG_FILE
sed -i -e "s/{{mail_provider}}/${MAIL_PROVIDER}/g" $CONFIG_FILE
sed -i -e "s/{{sendgrid_key}}/${SENDGRID_KEY}/g" $CONFIG_FILE
sed -i -e "s/{{smtp_host}}/${SMTP_HOST}/g" $CONFIG_FILE
sed -i -e "s/{{smtp_user}}/${SMTP_USER}/g" $CONFIG_FILE
sed -i -e "s/{{smtp_pass}}/${SMTP_PASS}/g" $CONFIG_FILE
sed -i -e "s/{{block_key}}/${BLOCK_KEY}/g" $CONFIG_FILE
sed -i -e "s/{{hash_key}}/${HASH_KEY}/g" $CONFIG_FILE
sed -i -e "s/{{metrics_password}}/${METRICS_PASSWORD}/g" $CONFIG_FILE
sed -i -e "s/{{pprof_password}}/${PPROF_PASSWORD}/g" $CONFIG_FILE
sed -i -e "s/{{certs_folder}}/${CERTIFICATES_FOLDER_ESC}/g" $CONFIG_FILE

# Certificates
if [ ! -f ${CERTIFICATES_FOLDER}/ca.pem ]; then

    cd /tmp
    openssl genrsa -out ca.key 2048
    openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.crt -batch
    openssl genrsa -out server.key 2048

    cat > csr.conf << EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = ES
ST = Catalunya
L = Barcelona
O = Balena
OU = BalenaLabs
CN = balena.io

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = balena
DNS.2 = balena.io
IP.1 = ${IP_ETH0}
IP.2 = ${IP_WLAN0}

EOF

    openssl req -new -key server.key -out server.csr -config csr.conf
    openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 10000 -extfile csr.conf
    
    cp ca.cert ${CERTIFICATES_FOLDER}/ca.pem
    cp server.cert ${CERTIFICATES_FOLDER}/cert.pem
    cp server.key ${CERTIFICATES_FOLDER}/key.pem

fi

# Run server
ttn-lw-stack -c ${CONFIG_FILE} start