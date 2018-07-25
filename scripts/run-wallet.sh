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
    declare -A ports=( [charlie]=4431 [devil]=4432 [eddy]=4433 )
    if [ ${ports[$wallet]+_} ]; then
	portmap=${ports[$wallet]}:443
    else
	portmap=443
    fi
    # runing electrum-daemon for $wallet
    docker run -d -v $USER-$wallet:/data --name $USER-$wallet-wallet $USER/electrum-daemon
    # runing laravel-electrum for $wallet
    docker run -d -v $USER-$wallet-db:/data -p ${portmap} -e ELECTRUM_DAEMON_HOST=$USER-$wallet-wallet  --link $USER-$wallet-wallet:$USER-$wallet-wallet --name $USER-$wallet-laravel $USER/laravel-electrum
else

    #export ZHSM=${ZHSM:-localhost}
    export DOCKER_HOST=tcp://$SSC_HOST:2376
    export DOCKER_TLS_VERIFY=1 
    export DOCKER_CERT_PATH=/etc/docker/cert.d/$SSC_HOST

    docker pull $REGISTRY/$USER/laravel-electrum # pull an image on SSC  
    docker pull $REGISTRY/$USER/electrum-daemon # pull an image on SSC

    # runing electrum-daemon for $wallet
    docker run -d -v $USER-$wallet:/data -e ZHSM=${ZHSM} --name $USER-$wallet-wallet $REGISTRY/$USER/electrum-daemon
    # runing laravel-electrum for $wallet
    docker run -d -v $USER-$wallet-db:/data -p 443 -e ELECTRUM_DAEMON_HOST=$USER-$wallet-wallet  --link $USER-$wallet-wallet:$USER-$wallet-wallet --name $USER-$wallet-laravel $REGISTRY/$USER/laravel-electrum
fi


