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

docker rm -f $user-$wallet-wallet
docker volume rm $user-$wallet


