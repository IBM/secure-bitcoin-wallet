#!/bin/bash

export NETWORK="--testnet"
# ENV ELECTRUM_USER electrum
# ENV ELECTRUM_HOME /home/$ELECTRUM_USER
export ELECTRUM_USER=root
export ELECTRUM_HOME=/${ELECTRUM_USER}
export ELECTRUM_PASSWORD=passw0rd
export ZHSM=${ZHSM}
export PYTHONPATH=/git/electrum
export APP_ROOT=/var/www/html/electrum
export ELECTRUM_DAEMON_HOST=localhost

# start an electrum daemon
pushd /git/electrum
./entrypoint-load.sh
popd

# start a laravel frontend with apache2
./entrypoint.sh
