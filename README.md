# The Open Network: Full node and Toncenter API, dockerised

This repository contains TON full node and Toncenter API builds unified into one Compose definition - to run as a service on any host machine.

This setup can be deployed on your host without any external dependencies: just clone this repo and run `bootstrap.sh`. Then wait for your full node to sync with the chain.

## Credentials

Many thanks to **EmelyanenkoK** and **neodiX42** for the [TON node build](https://github.com/ton-blockchain/ton/blob/master/docker/Dockerfile) which is used here without major changes, as well as **dungeon-master-666** for [TON HTTP API](https://github.com/toncenter/ton-http-api).

This setup has been created with the use of these sources.

## Functionality

TON node works in the full mode by default.

The API service can be configured to work in two modes:

- one-to-one (`onetoone`) - interacting with your node only;
- one-to-many (`onetomany`) - interacting with a set of nodes including your node.

## Prerequisites

To bootstrap and run the node, you have to install **Docker and Docker Compose** on your host.

For node system requirements, refer to the [official requirements](https://docs.ton.org/participate/run-nodes/full-node#:~:text=Hardware%20requirements%E2%80%8B&text=You%20need%20a%20machine%20with,a%20TON%20Blockchain%20Full%20Node.).

For MacOS, install `gnu-sed` to run the bootstrap script adequately:

```
brew install gnu-sed
```

Then, use `gsed` instead of `sed` in `bootstrap.sh`.

## Configuration

> **NB**: The `TON_NODE_IP` environment variable is fetched via an external resource. In case you need anything different, just remove the `export TON_NODE_IP` definition from `bootstrap.sh` and set `TON_NODE_IP` manually instead.

Both node and API are configured via the `.env` file.

In the **node part** of the file, you will find following parameters:

| Variable | Description | Default value |
| -------- | ----------- | ------------- |
| `NODE_VERSION` | Release version of the TON node - consider specifying the latest version | `2023.12` |
| `NODE_CONF_VOLUME` | External volume to store node configuration files | `${PWD}/config/node-config` |
| `NODE_LOG_VOLUME` | External volume to store node logs | `${PWD}/logs` |
| `NODE_STATE_VOLUME` | External volume to store the node DB | `${PWD}/db` |
| `NODE_CONFIG_URL` | Node config URL to download (find current config versions for Testnet and Mainnet below) | Testnet config |
| `NODE_PUBLIC_IP` | External public IP of your host to advertise the node on. This IP can be fetched automatically by `bootstrap.sh` | `TON_NODE_IP` environment variable |
| `NODE_LITESERVER` | Enable liteserver mode | `true` |
| `NODE_LITESERVER_PORT` | Node liteserver port | `43679` |
| `NODE_CONSOLE_PORT` | Node control plane port | `43678` |

In the **API part** of the file, you can set following HTTP API parameters:

| Variable | Description | Default value |
| -------- | ----------- | ------------- |
| `API_VERSION` | Release version of TON HTTP API | `2.0.31` |
| `API_NETWORK` | API network corresponding with your node | `testnet` |
| `API_MODE` | API interaction mode as above: `onetoone` or `onetomany` | `onetoone` |
| `API_CONF_VOLUME` | External volume to store API configs | `${PWD}/config/api-config` |
| `API_CACHE_ENABLED` | Set `1` to enable API cache | `0` |
| `API_LOGS_JSONIFY` | Set `1` to get logs in the JSON format | `0` |
| `API_LOGS_LEVEL` | API log level | `ERROR` |
| `API_TONLIB_LITESERVER_CONFIG` | Internal config path, fetched automatically from `API_NETWORK` and `API_MODE` variables | `/conf/${API_NETWORK}-config-${API_MODE}.json` |
| `API_TONLIB_PARALLEL_REQUESTS_PER_LITESERVER` | Maximal number of parallel request per liteserver | `50` |
| `API_TONLIB_REQUEST_TIMEOUT` | Timeout time of a request in milliseconds | `10000` |
| `API_GET_METHODS_ENABLED` | Set `1` to enable `GET` API methods | `1` |
| `API_JSON_RPC_ENABLED` | Set `1` to enable JSON RPC | `1` |
| `API_ROOT_PATH` | API root path after your hostname or IP | `"/"` |

## Running the node

To run the full node and API, change environment variables needed in the `.env` configuration and run the `bootstrap.sh` script.

This script will perform following operations:

1. Set your static IP as the `TON_NODE_IP` environment variable - to be used in the `.env` file further.
2. Apply `.env` variables to your shell environment.
3. Build local node and API images.
4. Run the node container. The node will bootstrap additionally with the use of the `./config/node-config/init.sh` script.
5. Run the standard `python` Docker image to set the `NODE_API_KEY` variable containing the generated HTTP API key of the node.
6. Add the obtained node API key to the desired API config.
7. Run the HTTP API container.

Then, just wait until your node is synchronised with the chain.

To interact with the API, refer to the [Toncenter API reference](https://toncenter.com/api/v2/).

## Removing public access from TON Liteserver endpoint

1. Prefix port-forwarding of TON node in `docker-compose.yaml` with "127.0.0.1" so it looks like
```yaml
ports:
  - 127.0.0.1:${NODE_CONSOLE_PORT}:${NODE_CONSOLE_PORT}
```

2. For TON HTTP API to be able to communicate with liteserver endpoint through internal network you need to change files in `config/api-config` depending on
network and mode.

3. Find `liteservers` section in config file.

4. Using `config/api-config/ip2dec.py` convert desired private IP address to decimal representation.
In `docker-compose.yaml` TON node container IP address is set to `172.18.0.2`, so it decimal value will be `-1408106494`.

5. Change the value of `.liteservers.ip` property inside config file to converted IP address from previous command.

6. To apply changes, restart TON HTTP API using `docker compose restart ton-api`.

## Updating the node

Just lift the release version in the `NODE_VERSION` variable of the `.env` file.

## Bootstrapping from snapshot

1. Run all steps mentioned above so your node is up and running.

2. Stop all containers using `docker compose down`

3. Download latest snapshot from https://dump.ton.org

4. Backup old db folder, i.e. you can rename it `mv db db_old`

5. Create new db folder `mkdir db`

6. Unpack downloaded archive to new `db` folder

7. Using following command copy some required files from `db_old` to `db` folder

```
cd db_old
cp -r server* client* liteserver* keyring ton-global.config db/
```

8. Start all services with `docker compose up -d`

9. Wait for node to be synced.

## Troubleshooting

1. Failed to parse config

`ton-node` logs:

```
[ 1][t 1][2023-12-24 23:20:03.489683013][validator-engine.cpp:3517][!validator-engine]	failed to parse config: [Error : 0 : failed to parse json: Unexpected symbol while parsing JSON Object]
```

If you see this error, check the downloaded and initialised `config.json` for syntax glitches. Change the file itself or the `init.sh` script accordingly. After this, you can either restart the node via Compose or bootstrap it again: in case you changed `init.sh`, remove the existing config and allow to reinitialise it via the script.

2. No nodes in the network

`ton-node` logs:

```
[ 2][t 6][2023-12-24 23:56:21.137193799][manager-init.cpp:86][!downloadproofreq]	failed to download proof link: [Error : 651 : no nodes]
```

This warning always appears during initial node start. Just wait until the node starts to sync.

3. Dead workers in `onetomany` mode

`ton-api` logs:

```
2023-12-25 10:49:47.910 | ERROR    | pyTON.manager:check_children_alive:232 - TonlibWorker #XXX is dead!!! Exit code: 12
2023-12-25 10:49:57.968 | ERROR    | pyTON.worker:report_last_block:118 - TonlibWorker #000 report_last_block exception of type LiteServerTimeout: LITE_SERVER_NETWORKadnl query timeout
```

If you see that some of workers other than `000` (your node) are dead - this means, these nodes are not accessible. This situation is not critical, so far there are accessible workers in the list including your node. Still, consider updating API configs from time to time.

## Checked on...

This setup works correctly with following software:

- Docker Compose v2.15.1
- Docker v20.10.23, build 7155243
- MacOS Sonoma 14.0 (Apple M1)
