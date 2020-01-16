#Bitcoin Digital Wallet

In this code pattern, we will deploy a Digital Wallet application in the public cloud. As digital wallets are targeted by hackers, it is important that the digital assets be protected in an environment that is also easily accessible by the user - also known as a "hot wallet". This includes having an environment where privileged admins nor external threats can compromise the data, via encryption and other mechanisms.

The Digital Wallet application consists of a [Web frontend](/laravel-electrum)and the [Electrum Bitcoin Client backend](/electrum), a modified version of [Electrum](https://github.com/spesmilo/electrum). The [Electrum Bitcoin Client backend](/electrum) runs as a JSON RPC server to maintain a bitcoin wallet by interacting with the bitcoin network. 

The Web frontend runs on [Laravel](https://laravel.com/), an emerging application framework written in PHP taking advantage of NodeJS for client-side rendering.
These two components are configured to run in a single [IBM Hyper Protect Virtual Server](https://cloud.ibm.com/catalog/services/hyper-protect-virtual-server).

It can optionally encrypt/decrypt a wallet file using [IBM Cloud Hyper Protect Crypto Services](https://cloud.ibm.com/catalog/services/hyper-protect-crypto-services) (zHSM) to protect the encryption key. 

The [Electrum frontend](/laravel-electrum), a modified version of [Electrum for Laravel 5.4+](https://github.com/AraneaDev/laravel-electrum). It runs as a Web frontend to interact with bitcoin users via a Web browser.



When you have completed this code pattern, you will understand how to:

* Build and run a Etherum Bitcoin digital wallet application 
* Stand up an IBM Cloud Hyper Protect Virtual Server
* (Optional) Integrate with IBM Cloud Hyper Protect Crypto Services to encrypt the wallet


## Steps

The frontend and backend applications can both be run locally, or in
the IBM Cloud in a Linux VM, for example an [IBM Cloud Hyper Protect
Virtual Server](https://cloud.ibm.com/catalog/services/hyper-protect-virtual-server).

##How to build the application

Start by cloning a monolithic-multistage branch from this repo and build a container out of it.

```
$ git clone https://github.com/IBM/secure-bitcoin-wallet.git
$ cd secure-bitcoin-wallet
$ docker build -t secure-bitcoin-wallet .
```

##How to run the application

The following sequence of commands starts a monolithic wallet container.
The *WALLET_VOLUME* and *PORT* should be a unique wallet volume name and port number, respectively, on the host. 

##How to encrypt the wallet (optional)
The *ZHSM* specifies the hostname of an ep11 server to use ZHSM. If this is not set, a default software AES is used.

```
$ WALLET_NAME=<wallet-name> (e.g. alice)
$ WALLET_USER=<wallet-user-name> (e.g. demo0)
$ PORT=<external-https-port>
$ ZHSM=<ep11server-address> (optional)
$ docker run -d -v ${WALLET_USER}-${WALLET_NAME}:/data -p ${PORT}:443 -e ZHSM=${ZHSM} --name ${WALLET_USER}-${WALLET_NAME}-wallet secure-bitcoin-wallet
```

##Use a Web browser to access the electrum wallet.

```
- Access https://hostname:port/electrum from a browser with the port number specified for the container.
- Accept a warning on a browser to use a self-signed certificate.
- Click "register" to register name, e-mail address, and password, for the first time. Or click "login" if already registered.
- Access https://hostname:port/electrum again if not redirected automatically.
- Create and load a wallet from a Wallet tab.
- Reload the browser.
- Select one of three tabs (`History`, `Requests`, `Receive`, `Send`, or `Sign`) to interact with the wallet.

```

Here is a sample screenshot of the wallet to send bitcoins to a recipient.

![A screenshot](https://github.com/IBM/secure-bitcoin-wallet/blob/images/images/secure-bitcoin-wallet-on-ibm-linuxone.png)*A Screenshot*

## WARNING: This software is for demonstration purposes only. Use at your own risk.


### Additional note

1. Persistent data

Wallet files are stored in a Docker volume, which can be examined by the following command.

```
$ docker volume inspect ${WALLET_VOLUME}
```

2. Reloading an existing wallet

To load a previously created wallet with a password in a docker volume, run the following command to create a wallet container

```
$ docker run -d -v ${WALLET_USER}-${WALLET_NAME}:/data -e WALLET=/data/electrum/testnet/wallets/default_wallet -e PASSWORD={wallet-password} -p ${PORT}:443 -e ZHSM=${ZHSM} --name ${WALLET_USER}-${WALLET_NAME}-wallet secure-bitcoin-wallet
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



iohara/9926f0791f1168acd7974b9dc4467e99) 
if you're contributing as an individual, or 
[corporate CLA form](https://gist.github.com/moriohara/018efe7c8b3247da3e77ddbf56f55c2e) 
if you're contributing as part of your job.

You are only required to do this once at on-line with [cla-assistant](https://github.com/cla-assistant/cla-assistant) when a PR is created, and then you are free to contribute to the secure-bitcoin-wallet project.
