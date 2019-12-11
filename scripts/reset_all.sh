#!/bin/bash

user=${$1:-$USER}

echo "wallet="$wallet
echo ""
echo "********** REMOVING WALLETS **********"
echo ""
./rm-wallet.sh $user charlie
./rm-wallet.sh $user devil
./rm-wallet.sh $user eddy
echo ""
echo "********** RUNNING WALLETS ***********"
echo ""
./run-wallet.sh $user charlie
./run-wallet.sh $user devil
./run-wallet.sh $user eddy
echo ""
echo "********** URLS **********************"
echo ""
./wallet-url.py $user charlie 
./wallet-url.py $user devil
./wallet-url.py $user eddy
echo ""
echo "********** DONE **********************"
