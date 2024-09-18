#!/bin/bash
set -e

build_all () {
  docker compose build
}

add_node_assets () {
  mkdir -p $NODE_STATE_VOLUME
  cp -a config/node-assets/. $NODE_STATE_VOLUME
}

deploy_node () {
  docker compose up -d ton-node
  sleep 5
}

set_http_api_key () {
  NODE_API_KEY=$(docker run --rm -v $API_CONF_VOLUME:/conf -v $NODE_STATE_VOLUME:/liteserver ton-api -c "python /conf/generate-api-key.py")
  sed -i "s~NODEAPIKEY~$NODE_API_KEY~g" ${API_CONF_VOLUME}/${API_NETWORK}-config-${API_MODE}.json
}

set_liteserver_ip () {
  DECIMAL_IP=$(docker run --rm -v $API_CONF_VOLUME:/conf ton-api -c "python /conf/ip2dec.py ${API_LITESERVER_IP:-TON_NODE_IP}")
  sed -i "s~LITESERVER_IP~$DECIMAL_IP~g" ${API_CONF_VOLUME}/${API_NETWORK}-config-${API_MODE}.json
}

deploy_api () {
  docker compose up -d ton-api
}

export TON_NODE_IP=$(curl -s https://ipinfo.io/ip)
source .env
build_all
add_node_assets
deploy_node
set_http_api_key
set_liteserver_ip
deploy_api