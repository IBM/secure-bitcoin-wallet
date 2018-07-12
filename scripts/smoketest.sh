#!/bin/bash

WALLET=${WALLET:-Alice}
PORT=${PORT:-4431}
VERBOSE=${VERBOSE:-"--verbose"}
WALLET_PATH=${WALLET_PATH:-"/data/electrum/testnet/wallets/default_wallet"}
PASSWORD=${PASSWORD:-passw0rd}
RUNTIME=runc
docker run -d -v ${WALLET}:/data --runtime ${RUNTIME} -e ZHSM=${ZHSM} -e VERBOSE="${VERBOSE}" -e WALLET=${WALLET_PATH} -e PASSWORD=${PASSWORD} --name ${WALLET}-wallet electrum-daemon
docker run -d -v ${WALLET}-db:/data -p ${PORT}:443 -e ELECTRUM_DAEMON_HOST=${WALLET}-wallet -e VERBOSE="${VERBOSE}" --link ${WALLET}-wallet:${WALLET}-wallet --name ${WALLET}-laravel laravel-electrum
