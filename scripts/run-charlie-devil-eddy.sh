#!/bin/bash

if [ $# == 1 ] ; then
    USER=$1
fi
echo "USER="$USER

DOCKER_CONTENT_TRUST=${DOCKER_CONTENT_TRUST:-0}
REGISTRY=${REGISTRY:-localhost:5000}
ARCH=`uname -m`
if [ $ARCH = "x86_64" ]; then
  ARCH="amd64"
fi

wallets=("charlie" "devil" "eddy")

for wallet in "${wallets[@]}" ; do

    docker pull $REGISTRY/$USER/electrum-daemon-$ARCH
    docker pull $REGISTRY/$USER/laravel-electrum-$ARCH
    
    # runing electrum-daemon for $wallet
    docker run -d -v $USER-$wallet:/data --name $USER-$wallet-wallet $REGISTRY/$USER/electrum-daemon-$ARCH ./entrypoint-load.sh

    # runing laravel-electrum for $wallet
    docker run -d -v $USER-$wallet-db:/data -p 443 -e ELECTRUM_DAEMON_HOST=$USER-$wallet-wallet  --link $USER-$wallet-wallet:$USER-$wallet-wallet --name $USER-$wallet-laravel $REGISTRY/$USER/laravel-electrum-$ARCH
done
