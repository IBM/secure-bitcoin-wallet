#!/bin/bash

if [ $# == 1 ] ; then
    USER=$1
fi
echo "USER="$USER

RUNTIME=${RUNTIME:-runq}
DOCKER_CONTENT_TRUST=${DOCKER_CONTENT_TRUST:-0}
REGISTRY=${REGISTRY:-localhost:5000}
ARCH=`uname -m`
if [ $ARCH = "x86_64" ]; then
  ARCH="amd64"
fi

wallets=("alice" "bob")

for wallet in "${wallets[@]}" ; do

    ./docker-ssc pull $REGISTRY/$USER/electrum-daemon-$ARCH
    ./docker-ssc pull $REGISTRY/$USER/laravel-electrum-$ARCH
    
    # runing electrum-daemon for $wallet
    ./docker-ssc run -d -v $USER-$wallet:/data --runtime ${RUNTIME} -e ZHSM=${ZHSM} --name $USER-$wallet-wallet $REGISTRY/$USER/electrum-daemon-$ARCH ./entrypoint-load.sh

    # runing laravel-electrum for $wallet
    ./docker-ssc run -d -v $USER-$wallet-db:/data -p 443 -e ELECTRUM_DAEMON_HOST=$USER-$wallet-wallet  --link $USER-$wallet-wallet:$USER-$wallet-wallet --name $USER-$wallet-laravel $REGISTRY/$USER/laravel-electrum-$ARCH
done
