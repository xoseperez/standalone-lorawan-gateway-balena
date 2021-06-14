#!/bin/sh

# Get IPs
if [ "$BALENA_DEVICE_UUID" != "" ]; then

IP_LAN=$(curl -sX GET "https://api.balena-cloud.com/v5/device?\$filter=uuid%20eq%20'$BALENA_DEVICE_UUID'" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $BALENA_API_KEY" | \
jq ".d | .[0] | .ip_address" | sed 's/"//g')

IP_WAN=$(curl -sX GET "https://api.balena-cloud.com/v5/device?\$filter=uuid%20eq%20'$BALENA_DEVICE_UUID'" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $BALENA_API_KEY" | \
jq ".d | .[0] | .public_address" | sed 's/"//g')

else

#IP_LAN=${IP_LAN:-$(hostname -i)}
IP_ETH0=$(ip a s eth0 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)
IP_WLAN0=$(ip a s wlan0 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)
IP_LAN=${IP_LAN:-$(echo "${IP_ETH0} ${IP_WLAN0}" | sed 's/ \s*/ /g' | sed 's/^ *//g' | sed 's/ *$//g')}
IP_WAN=${IP_WAN:-$(wget -q -O - ipinfo.io/ip)}

fi 

# Get configuration
CONFIG_FILE=/home/thethings/ttn-lw-stack-docker.yml
DATA_FOLDER=/srv/data
DATA_FOLDER_ESC=$(echo "${DATA_FOLDER}" | sed 's/\//\\\//g')

SERVER_NAME=${SERVER_NAME:-The Things Stack}
DOMAIN=${DOMAIN:-${IP_LAN% *}}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@thethings.example.com}
NOREPLY_EMAIL=${NOREPLY_EMAIL:-noreply@thethings.example.com}

ADMIN_PASSWORD=${ADMIN_PASSWORD:-changeme}
CONSOLE_SECRET=${CONSOLE_SECRET:-console}
DEVICE_CLAIMING_SECRET=${DEVICE_CLAIMING_SECRET:-device_claiming}
METRICS_PASSWORD=${METRICS_PASSWORD:-metrics}
PPROF_PASSWORD=${PPROF_PASSWORD:-pprof}

BLOCK_KEY=$(openssl rand -hex 32)
HASH_KEY=$(openssl rand -hex 64)
if [ ! $SMTP_HOST == "" ]; then
    MAIL_PROVIDER="smtp"
else
    MAIL_PROVIDER="sendgrid"
fi

# Build config file
cp ${CONFIG_FILE}.template ${CONFIG_FILE}
sed -i -e "s/{{server_name}}/${SERVER_NAME}/g" $CONFIG_FILE
sed -i -e "s/{{admin_email}}/${ADMIN_EMAIL}/g" $CONFIG_FILE
sed -i -e "s/{{noreply_email}}/${NOREPLY_EMAIL}/g" $CONFIG_FILE
sed -i -e "s/{{console_secret}}/${CONSOLE_SECRET}/g" $CONFIG_FILE
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
sed -i -e "s/{{device_claiming_secret}}/${DEVICE_CLAIMING_SECRET}/g" $CONFIG_FILE
sed -i -e "s/{{data_folder}}/${DATA_FOLDER_ESC}/g" $CONFIG_FILE

# Certificates are rebuild on subject change
SUBJECT_COUNTRY=${SUBJECT_COUNTRY:-ES}
SUBJECT_STATE=${SUBJECT_STATE:-Catalunya}
SUBJECT_LOCATION=${SUBJECT_LOCATION:-Barcelona}
SUBJECT_ORGANIZATION=${SUBJECT_ORGANIZATION:-TTN Catalunya}
EXPECTED_SIGNATURE="$SUBJECT_COUNTRY $SUBJECT_STATE $SUBJECT_LOCATION $SUBJECT_ORGANIZATION $DOMAIN"
CURRENT_SIGNATURE=$(cat ${DATA_FOLDER}/certificates_signature)

if [ "$CURRENT_SIGNATURE" != "$EXPECTED_SIGNATURE" ]; then

    cd /tmp
    
    echo "{\"names\":[{\"C\":\"$SUBJECT_COUNTRY\",\"ST\":\"$SUBJECT_STATE\",\"L\":\"$SUBJECT_LOCATION\",\"O\":\"$SUBJECT_ORGANIZATION\"}]}" > ca.json
    cfssl genkey -initca ca.json | cfssljson -bare ca

    echo "{\"hosts\":[\"$DOMAIN\"],\"names\":[{\"C\":\"$SUBJECT_COUNTRY\",\"ST\":\"$SUBJECT_STATE\",\"L\":\"$SUBJECT_LOCATION\",\"O\":\"$SUBJECT_ORGANIZATION\"}]}" > cert.json
    cfssl gencert -ca ca.pem -ca-key ca-key.pem cert.json | cfssljson -bare cert

    cp ca.pem ${DATA_FOLDER}/ca.pem
    cp cert-key.pem ${DATA_FOLDER}/key.pem
    cp cert.pem ${DATA_FOLDER}/cert.pem

    echo $EXPECTED_SIGNATURE > ${DATA_FOLDER}/certificates_signature

fi

# Initialization
EXPECTED_SIGNATURE="$ADMIN_EMAIL $ADMIN_PASSWORD $CONSOLE_SECRET $DOMAIN"
CURRENT_SIGNATURE=$(cat ${DATA_FOLDER}/database_signature)
if [ "$CURRENT_SIGNATURE" != "$EXPECTED_SIGNATURE" ]; then

    ttn-lw-stack -c ${CONFIG_FILE} is-db init
    ttn-lw-stack -c ${CONFIG_FILE} is-db create-admin-user \
        --id admin \
        --email "${ADMIN_EMAIL}" \
        --password "${ADMIN_PASSWORD}"
    ttn-lw-stack -c ${CONFIG_FILE} is-db create-oauth-client \
        --id cli \
        --name "Command Line Interface" \
        --owner admin \
        --no-secret \
        --redirect-uri "local-callback" \
        --redirect-uri "code"

    ttn-lw-stack -c ${CONFIG_FILE} is-db create-oauth-client \
        --id console \
        --name "Console" \
        --owner admin \
        --secret "${CONSOLE_SECRET}" \
        --redirect-uri "https://${DOMAIN}/console/oauth/callback" \
        --redirect-uri "/console/oauth/callback" \
        --logout-redirect-uri "https://${DOMAIN}/console" \
        --logout-redirect-uri "/console"

    echo $EXPECTED_SIGNATURE > ${DATA_FOLDER}/database_signature

fi

# Run server
ttn-lw-stack -c ${CONFIG_FILE} start