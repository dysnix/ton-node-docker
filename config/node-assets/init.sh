#!/usr/bin/env bash

# Handling for the initial node setup

# Download the global config
if [ -f "./ton-global.config" ]; then
    echo -e "\e[1;33m[=]\e[0m Found existing global config, skipping"
else
    echo -e "\e[1;32m[+]\e[0m Downloading provided global config."
    wget -q $GCONFURL -O /var/ton-work/db/ton-global.config
fi

# Init local config with IP:PORT
if [ -f "./config.json" ]; then
    echo -e "\e[1;33m[=]\e[0m Found existing local config, skipping"
else
    echo -e "\e[1;32m[+]\e[0m Using provided IP: $PUBLIC_IP:$CONSOLE_PORT"
    /usr/bin/ton/validator-engine/validator-engine -C /var/ton-work/db/ton-global.config --db /var/ton-work/db --ip "$PUBLIC_IP:$CONSOLE_PORT"
fi

# Generating server certificate
if [ -f "./server" ]; then
    echo -e "\e[1;33m[=]\e[0m Found existing server certificate, skipping"
else
    echo -e "\e[1;32m[+]\e[0m Generating and installing server certificate for remote control"
    read -r SERVER_ID1 SERVER_ID2 <<< $(/usr/bin/ton/utils/generate-random-id -m keys -n server)
    echo "Server IDs: $SERVER_ID1 $SERVER_ID2"
    cp server /var/ton-work/db/keyring/$SERVER_ID1
fi

# Generating client certificate
if [ -f "./client" ]; then
    echo -e "\e[1;33m[=]\e[0m Found existing client certificate, skipping"
else
    read -r CLIENT_ID1 CLIENT_ID2 <<< $(/usr/bin/ton/utils/generate-random-id -m keys -n client)
    echo -e "\e[1;32m[+]\e[0m Generated client private certificate $CLIENT_ID1 $CLIENT_ID2"
    echo -e "\e[1;32m[+]\e[0m Generated client public certificate"
    # Adding client permissions
    sed -e "s/CONSOLE-PORT/\"$(printf "%q" $CONSOLE_PORT)\"/g" -e "s~SERVER-ID~\"$(printf "%q" $SERVER_ID2)\"~g" -e "s~CLIENT-ID~\"$(printf "%q" $CLIENT_ID2)\"~g" /var/ton-work/db/control.template > /var/ton-work/db/control.new
    sed -e "s~\"control\"\ \:\ \[~$(printf "%q" $(cat control.new))~g" /var/ton-work/db/config.json > /var/ton-work/db/config.json.new
    mv /var/ton-work/db/config.json.new /var/ton-work/db/config.json
fi

# Liteserver
if [ -z "$LITESERVER" ]; then
    echo -e "\e[1;33m[=]\e[0m Liteserver disabled"
else
    if [ -f "./liteserver" ]; then
        echo -e "\e[1;33m[=]\e[0m Found existing liteserver certificate, skipping"
    else
        echo -e "\e[1;32m[+]\e[0m Generating and installing liteserver certificate for remote control"
        read -r LITESERVER_ID1 LITESERVER_ID2 <<< $(/usr/bin/ton/utils/generate-random-id -m keys -n liteserver)
        echo "Liteserver IDs: $LITESERVER_ID1 $LITESERVER_ID2"
        cp liteserver /var/ton-work/db/keyring/$LITESERVER_ID1
        if [ -z "$LITE_PORT" ]; then
            LITE_PORT="43679"
        fi
        LITESERVERS=$(printf "%q" "\"liteservers\":[{\"id\":\"$LITESERVER_ID2\",\"port\":\"$LITE_PORT\"}")
        sed -e "s~\"liteservers\"\ \:\ \[~$LITESERVERS~g" config.json > config.json.liteservers
        mv config.json.liteservers config.json
    fi
fi

echo -e "\e[1;32m[+]\e[0m Running validator-engine"

exec "$@"