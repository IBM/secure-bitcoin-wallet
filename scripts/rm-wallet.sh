#!/bin/bash

if [ $# == 1 ] ; then
    wallet=$1
else
    echo "usage: "$0" <walletname>"
    exit
fi
echo "wallet="$wallet

DOCKER_CONTENT_TRUST=${DOCKER_CONTENT_TRUST:-0}
#REGISTRY=${REGISTRY:-localhost:5000}

ARCH=`uname -m`
if [ $ARCH = "x86_64" ]; then
    ARCH="amd64"
else
    #export ZHSM=${ZHSM:-localhost}
    export DOCKER_HOST=tcp://$SSC_HOST:2376
    export DOCKER_TLS_VERIFY=1 
    export DOCKER_CERT_PATH=/etc/docker/cert.d/$SSC_HOST
fi

# removing electrum-daemon and laravel-electrum containers for "$wallet"
docker rm -f $USER-$wallet-wallet $USER-$wallet-laravel
# removing wallet and wallet-db volumes for "$wallet"
docker volume rm $USER-$wallet $USER-$wallet-db


