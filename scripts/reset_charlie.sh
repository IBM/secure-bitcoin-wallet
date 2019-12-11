#!/bin/bash

user=${$1:-$USER}

echo ""
echo "********** REMOVING WALLETS **********"
echo ""
./rm-wallet.sh $user charlie
echo ""
echo "********** RUNNING WALLETS ***********"
echo ""
./run-wallet.sh $user charlie
echo ""
echo "********** URL *********** ***********"
echo ""
./wallet-url.py $user charlie
echo ""
echo "********** DONE **********************"
echo ""
