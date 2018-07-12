#!/bin/bash


#ELECTRUM_UID=2000
#ELECTRUM_GID=2000

wallet="wallet"
wallet_file_path=""

if [ $# -eq 1 ]; then
    wallet=$1
elif [ $# -eq 2 ]; then
    wallet=$1
    wallet_file_path=$2
fi

echo "wallet_name="`docker volume create $wallet`

vol=`docker volume inspect $wallet | grep Mountpoint | sed s/\"Mountpoint\":// | sed s/\"//g | sed s/,//`

electrum=$vol/electrum

echo "wallet_path="$electrum

sudo mkdir -p $electrum

if [ ! -z $wallet_file_path ]; then
    wallet_base=$(basename $wallet_file_path)
    echo $electrum/testnet/wallets/$wallet_base
    if [ -e $electrum/testnet/wallets/$wallet_base ]; then
	echo "skipping copying a wallet file since it already exists"
    else
	sudo mkdir -p $electrum/testnet/wallets
	sudo cp $wallet_file_path $electrum/testnet/wallets
    fi
fi

#sudo chown -R $ELECTRUM_UID:$ELECTRUM_GID $electrum

