#!/bin/bash
##############################################################################
# Copyright 2020 IBM Corp. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
##############################################################################

if [ $# == 1 ] ; then
    wallet=$1
    wallet_vol=$wallet
elif [ $# == 2 ] ; then
    user=$1
    wallet=$2
    wallet_vol=$user-$wallet
else
    echo "usage: "$0" [username] walletname (e.g. demo0 charlie)"
    exit
fi
echo "wallet="$wallet

DOCKER_CONTENT_TRUST=${DOCKER_CONTENT_TRUST:-0}
CONTAINER_IMAGE=${CONTAINER_IMAGE:-secure-bitcoin-wallet}

# associative array doesn't work on Mac with bash 3.x
# declare -A ports=([charlie]=4431 [devil]=4432 [eddy]=4433)

# this works both on Mac and Linux
declare port_charlie=4431 port_devil=4432 port_eddy=4433
port=port_$wallet
port=${!port}

if [ ${port} ]; then
    portmap=$port:443
else
    portmap=443
fi

docker run -d -v $wallet_vol:/data -p ${portmap} --name $wallet_vol-wallet $CONTAINER_IMAGE

port=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "443/tcp") 0).HostPort}}' $wallet_vol-wallet)

echo "a wallet is running in container $wallet_vol-wallet at port $port"

