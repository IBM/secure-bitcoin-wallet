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

if [ $(uname) != "Linux" ] ; then
    echo "this script works only on Linux"
    exit
fi

if [ $# == 0 ] ; then
    user=''
    wallet=charlie
elif [ $# == 1 ] ; then
    user=''
    wallet=$1
elif [ $# == 2 ] ; then
    user=$1
    wallet=$2
else
    echo "usage: "$0" [[username] walletname] (e.g. demo0 charlie)"
    exit
fi
echo "wallet="$wallet

echo ""
echo "************** CHARLIE'S WALLET PROCESS ID ******************"
echo ""
pid=$(./wallet-pid.py $user $wallet)
echo "Wallet Process ID:"$pid
echo ""
echo "************** CHARLIE'S WALLET MEMORY DUMP *****************"
echo ""
sudo gcore $pid
strings core.$pid | grep \"seed\"
echo ""
