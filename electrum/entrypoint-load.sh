#!/usr/bin/env sh
set -ex

mkdir -p /data/electrum/testnet/wallets
touch /data/electrum/keystore.sqlite
# chown electrum /data/electrum/keystore.sqlite

if [ ! -e ${ELECTRUM_HOME}/.electrum ]; then
    ln -s /data/electrum ${ELECTRUM_HOME}/.electrum
fi

ELECTRUM_USER="electrum"

echo "ZHSM=${ZHSM}"

# Run electrum in a GUI mode when specified
if [ "${ELECTRUM_MODE}" = "GUI" ]; then
    ./run_electrum ${VERBOSE} ${NETWORK} gui
else
    ./run_electrum ${NETWORK} setconfig rpcuser ${ELECTRUM_USER}
    ./run_electrum ${NETWORK} setconfig rpcpassword ${ELECTRUM_PASSWORD}
    ./run_electrum ${NETWORK} setconfig rpchost 0.0.0.0
    ./run_electrum ${NETWORK} setconfig rpcport 7777

    ./run_electrum daemon ${VERBOSE} ${NETWORK} start

    if [ -z "${WALLET}" ]; then
	./run_electrum daemon ${VERBOSE} ${NETWORK} status
    else
	echo ${PASSWORD} > /tmp/pass
	if [ -z "${MULTISIG}" ]; then
	    ./run_electrum daemon ${VERBOSE} ${NETWORK} --wallet ${WALLET} load_wallet < /tmp/pass 1> /tmp/load-wallet.log 2> /tmp/load-wallet.err
	else
	    ./run_electrum daemon ${VERBOSE} ${NETWORK} --wallet ${WALLET} load_multisig_wallet < /tmp/pass 1> /tmp/load-multisig-wallet.log 2> /tmp/load-multisig-wallet.err
	fi
	rm /tmp/pass
	./run_electrum daemon ${VERBOSE} ${NETWORK} --wallet ${WALLET} status
    fi
fi

# wait here in a daemon mode
#while true; do
#  tail -f /dev/null & wait ${!}
#done
