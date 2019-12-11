# Secure Bitcoin Wallet on LinuxONE (Monolithic Multistage)

This branch creates a monolithic container with a multistage Dockerfile to package a Web Frontend and an Electrum Bitcoin Client in a single container, using [Electrum 3.3.6](https://github.com/spesmilo/electrum/tree/3.3.6).

## Electrum Bitcoin Client with Web Frontend

Secure Bitcoin Wallet is a Dockernized version of [Electrum Bitcoin Client](/electrum) 
with a [Web frontend](/laravel-electrum) to run on [IBM LinuxONE](https://developer.ibm.com/linuxone/), 
as shown in the following block diagram.
The [Electrum Bitcoin Client](/electrum), a modified version of [Electrum](https://github.com/spesmilo/electrum), runs as a JSON RPC server to maintain 
a bitcoin wallet by interacting with the bitcoin network.
It can optionally encrypt/decrypt a wallet file using an [EP11 crypto server](https://www.ibm.com/support/knowledgecenter/en/linuxonibm/com.ibm.linux.z.lxce/lxce_stack.html) (zHSM) to protect the encryption key. 
The [Electrum frontend](/laravel-electrum), a modified version of [Electrum for Laravel 5.4+](https://github.com/AraneaDev/laravel-electrum),
runs as a Web frontend to interact with bitcoin users via a Web browser.
It runs on [Laravel](https://laravel.com/), an emerging application framework written in PHP taking advantage of NodeJS for client-side rendering.
In this monolithic version, these two componets are configured to run in a single Docker container on x86 or in a single Hyper Protect Virtual Server on a 
LinuexONE Secure Service Container (SSC).

![A blockdiagram](https://github.com/IBM/secure-bitcoin-wallet/blob/images/images/blockdiagram-monolithic.png)*Block Diagram*

Here is a sample screenshot of the wallet to send bitcoins to a recipient.

![A screenshot](https://github.com/IBM/secure-bitcoin-wallet/blob/images/images/secure-bitcoin-wallet-on-ibm-linuxone.png)*A Screenshot*

## WARNING: This software is for demonstration purposes only. Use at your own risk.

### How to build on a regular Linux or Mac

Just clone a monolithic-multistage branch from this repo and build a container out of it.

```
$ git clone https://github.com/IBM/secure-bitcoin-wallet.git
$ cd secure-bitcoin-wallet
$ git checkout monolithic-multistage
$ docker build -t secure-bitcoin-wallet .
```

### How to run on a regular Linux or Mac

The following sequence of commands starts a monolithic wallet container.
The *WALLET_VOLUME* and *PORT* should be a unique wallet volume name and port number, respectively, on the host. 
The *ZHSM* specifies the hostname of an ep11 server to use ZHSM. If this is not set, a default software AES is used.

```
$ WALLET_VOLUME=<wallet-volume-name> (e.g. alice)
$ WALLET_USER=<wallet-user-name> (e.g. demo0)
$ PORT=<external-https-port>
$ ZHSM=<ep11server-address> (optional)
$ docker run -d -v ${WALLET_VOLUME}:/data -p ${PORT}:443 -e ZHSM=${ZHSM} --name ${WALLET_USER}-${WALLET_VOLUME}-wallet secure-bitcoin-wallet
```

Use a Web browser to access the electrum wallet.

- Access https://hostname:port/electrum from a browser with the port number specified for the container.
- Accept a warning on a browser to use a self-signed certificate.
- Click "register" to register name, e-mail address, and password, for the first time. Or click "login" if already registered.
- Access https://hostname:port/electrum again if not redirected automatically.
- Create and load a wallet from a Wallet tab.
- Reload the browser.
- Select one of three tabs (`History`, `Requests`, `Receive`, `Send`, or `Sign) to interact with the wallet.

### Additional note

1. Persistent data

Wallet files are stored in a Docker volume, which can be examined by the following command.

```
$ docker volume inspect ${WALLET_VOLUME}
```

2. Reloading an existing wallet

To load a previously created wallet with a password in a docker volume, run the following command to create a wallet container

```
$ docker run -d -v ${WALLET_VOLUME}:/data -e WALLET=/data/electrum/testnet/wallets/default_wallet -e PASSWORD={wallet-password} -p ${PORT}:443 -e ZHSM=${ZHSM} --name wallet-${WALLET_VOLUME} secure-bitcoin-wallet
```

## License

[Apache 2.0](https://github.com/IBM/secure-bitcoin-wallet/blob/master/LICENSE)

## Contributor License Agreement (CLA)

To contribute to the secure-bitcoin-wallet project, it is required to sign the 
[individual CLA form](https://gist.github.com/moriohara/9926f0791f1168acd7974b9dc4467e99) 
if you're contributing as an individual, or 
[corporate CLA form](https://gist.github.com/moriohara/018efe7c8b3247da3e77ddbf56f55c2e) 
if you're contributing as part of your job.

You are only required to do this once at on-line with [cla-assistant](https://github.com/cla-assistant/cla-assistant) when a PR is created, and then you are free to contribute to the secure-bitcoin-wallet project.
