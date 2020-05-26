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

echo "removing Dcoker container $wallet_vol-wallet"
docker rm -f $wallet_vol-wallet
echo "removing Docker volume $wallet_vol"
docker volume rm $wallet_vol


