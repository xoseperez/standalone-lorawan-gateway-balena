#!/bin/sh

# Get service coonfiguration
RESPONSE=$(curl -sX GET "https://api.balena-cloud.com/v6/device?\$filter=uuid%20eq%20'$BALENA_DEVICE_UUID'" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $BALENA_API_KEY")
BALENA_ID=$(echo $RESPONSE | jq ".d | .[0] | .id")
IP_LAN=$(echo $RESPONSE | jq ".d | .[0] | .ip_address" | sed 's/"//g')
IP_WAN=$(echo $RESPONSE | jq ".d | .[0] | .public_address" | sed 's/"//g')

# Utility function to create or update a device environment variables
balena_set_variable() {
    
    NAME=$1
    VALUE=$2
    
    ID=$(curl -sX GET "https://api.balena-cloud.com/v6/device_environment_variable" -H "Content-Type: application/json" -H "Authorization: Bearer $BALENA_API_KEY" | jq '.d | .[] | select(.name == "'$NAME'") | .id')
    
    if [ "$ID" == "" ]; then

        curl -sX POST \
            "https://api.balena-cloud.com/v6/device_environment_variable" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $BALENA_API_KEY" \
            --data "{\"device\": \"$BALENA_ID\",\"name\": \"$NAME\",\"value\": \"$VALUE\"}" 2> /dev/null

    else

        curl -X PATCH \
            "https://api.balena-cloud.com/v6/device_environment_variable($ID)" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $BALENA_API_KEY" \
            --data "{\"value\": \"$VALUE\"}" 2> /dev/null

    fi

}

# Check configuration
if [ "$DOMAIN" == "" ]
then
    echo -e "\033[91mERROR: Missing configuration, define DOMAIN variable.\033[0m"
	sleep infinity
fi

# Get configuration
CONFIG_FILE=/home/thethings/ttn-lw-stack-docker.yml
DATA_FOLDER=/srv/data
DATA_FOLDER_ESC=$(echo "${DATA_FOLDER}" | sed 's/\//\\\//g')

SERVER_NAME=${SERVER_NAME:-The Things Stack}
IP_LAN=$(echo $IP_LAN | sed 's/ /,/g')
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
CURRENT_SIGNATURE=$(cat ${DATA_FOLDER}/certificates_signature 2> /dev/null)

if [ "$CURRENT_SIGNATURE" != "$EXPECTED_SIGNATURE" ]; then

    cd /tmp
    
    echo '{"CN":"'$SUBJECT_ORGANIZATION CA'","key":{"algo":"rsa","size":2048},"names":[{"C":"'$SUBJECT_COUNTRY'","ST":"'$SUBJECT_STATE'","L":"'$SUBJECT_LOCATION'","O":"'$SUBJECT_ORGANIZATION'"}]}' > ca.json
    cfssl genkey -initca ca.json | cfssljson -bare ca

    echo '{"CN":"'$DOMAIN'","hosts":["'$DOMAIN'","'$(echo $IP_LAN | sed 's/,/\",\"/')'"],"key":{"algo":"rsa","size":2048},"names":[{"C":"'$SUBJECT_COUNTRY'","ST":"'$SUBJECT_STATE'","L":"'$SUBJECT_LOCATION'","O":"'$SUBJECT_ORGANIZATION'"}]}' > cert.json
    cfssl gencert -hostname "$DOMAIN,$IP_LAN,$IP_WAN" -ca ca.pem -ca-key ca-key.pem cert.json | cfssljson -bare cert

    cp ca.pem ${DATA_FOLDER}/ca.pem
    cp ca-key.pem ${DATA_FOLDER}/ca-key.pem
    cp cert.pem ${DATA_FOLDER}/cert.pem
    cp cert-key.pem ${DATA_FOLDER}/key.pem

    echo $EXPECTED_SIGNATURE > ${DATA_FOLDER}/certificates_signature

fi

# We populate the TC_TRUST and TC_URI for a possible Balena BasicStation service running on the same machine
TC_TRUST=$(cat ${DATA_FOLDER}/ca.pem)
TC_TRUST=${TC_TRUST//$'\n'/}
balena_set_variable "TC_TRUST" "$TC_TRUST"
balena_set_variable "TC_URI" "wss://$DOMAIN:8887"

# Initialization
EXPECTED_SIGNATURE="$ADMIN_EMAIL $ADMIN_PASSWORD $CONSOLE_SECRET $DOMAIN"
CURRENT_SIGNATURE=$(cat ${DATA_FOLDER}/database_signature 2> /dev/null)
if [ "$CURRENT_SIGNATURE" != "$EXPECTED_SIGNATURE" ]; then

    ttn-lw-stack -c ${CONFIG_FILE} is-db init
    
    if [ $? -eq 0 ]; then

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

fi

# Run server
ttn-lw-stack -c ${CONFIG_FILE} start

# Do not restart so quick
echo -e "\033[91mERROR: LNS exited, waiting 60 seconds and then rebooting service.\033[0m"
sleep 60
exit 1
