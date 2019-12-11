#!/bin/bash

if [ $# == 1 ] ; then
    user=$USER
    wallet=$1
elif [ $# == 2 ] ; then
    user=$1
    wallet=$2
else
    echo "usage: "$0" [username] walletname (e.g. demo0 charlie)"
    exit
fi
echo "wallet="$wallet

DOCKER_CONTENT_TRUST=${DOCKER_CONTENT_TRUST:-0}
CONTAINER_IMAGE=${CONTAINER_IMAGE:-secure-bitcoin-wallet}

declare -A ports=( [charlie]=4431 [devil]=4432 [eddy]=4433 )
if [ ${ports[$wallet]+_} ]; then
    portmap=${ports[$wallet]}:443
else
    portmap=443
fi
docker run -d -v $user-$wallet:/data -p ${portmap} --name $user-$wallet-wallet $CONTAINER_IMAGE

