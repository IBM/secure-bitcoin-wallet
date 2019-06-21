# Secure Bitcoin Wallet on LinuxONE (Monolithic)

This branch creates a monolithic container to package a Web Frontend and an Electrum Bitcoin Client in a single container, using [Electrum 3.3.6](https://github.com/spesmilo/electrum/tree/3.3.6).

This README is under construction. The procedure to build and run containers is obsolete.


## Electrum Bitcoin Client with Web Frontend

Secure Bitcoin Wallet is a Dockernized version of [Electrum Bitcoin Client](/electrum) 
with a [Web frontend](/laravel-electrum) to run on [IBM LinuxONE](https://developer.ibm.com/linuxone/), 
as shown in the following block diagram.
The [Electrum Bitcoin Client](/electrum), a modified version of [Electrum](https://github.com/spesmilo/electrum), runs as a JSON RPC server to maintain 
a bitcoin wallet by interacting with the bitcoin network.
It can encrypt/decrypt a wallet file using an [EP11 crypto server](https://www.ibm.com/support/knowledgecenter/en/linuxonibm/com.ibm.linux.z.lxce/lxce_stack.html) (zHSM) to protect the encryption key. 
The [Electrum frontend](/laravel-electrum), a modified version of [Electrum for Laravel 5.4+](https://github.com/AraneaDev/laravel-electrum),
runs as a Web frontend to interact with bitcoin users via a Web browser.
It runs on [Laravel](https://laravel.com/), an emerging application framework written in PHP taking advantage of NodeJS for client-side rendering.
These two components are dockernized to run in a Docker container on x86 or in an isolated container on a 
LinuexONE Secure Service Container (SSC).

![A blockdiagram](https://github.com/IBM/secure-bitcoin-wallet/blob/images/images/blockdiagram.png)*Block Diagram*

Here is a sample screenshot of the wallet to send bitcoins to a recipient.

![A screenshot](https://github.com/IBM/secure-bitcoin-wallet/blob/images/images/secure-bitcoin-wallet-on-ibm-linuxone.png)*A Screenshot*

## WARNING: This software is for demonstration purposes only. Use at your own risk.

### How to build

Build a php:apache docker image if it is not available from an official php repository.

```
$ git clone https://github.com/docker-library/php.git
$ cd php/7.2/stretch/apache
$ docker build -t php:apache .
```

Then, build an Elecrum wallet and its frontend by using docker-compose.

```
$ git clone https://github.com/IBM/secure-bitcoin-wallet.git
$ cd secure-bitcoin-wallet/laravel-electrum
$ docker-compose -f docker-compose-build.yml build
```

### How to run

The following sequence of commands starts a pair of containers, electrum-daemon and laravel-electrum. 
The *wallet* should be a unique wallet name on the host. The *RUNTIME* specifies the container runtime: 
*runc* for regular Docker containers, or *runq* for isolated containers on SSC. The *ZHSM*
specifies the hostname of an ep11 server to use ZHSM. If this is not set, the default software AES is used.

```
$ WALLET=<wallet-name> (e.g. alice)
$ PORT=<external-https-port>
$ RUNTIME=<container-runtme> (e.g. runc for regular Docker containers or runq for isolated containers on SSC)
$ ZHSM=<ep11server-address> (optional)
$ docker run -d -v ${WALLET}:/data --runtime ${RUNTIME} -e ZHSM=${ZHSM} --name ${WALLET}-wallet electrum-daemon
$ docker run -d -v ${WALLET}-db:/data -p ${PORT}:443 -e ELECTRUM_DAEMON_HOST=${WALLET}-wallet  --link ${WALLET}-wallet:${WALLET}-wallet --name ${WALLET}-laravel laravel-electrum
```

Use a Web browser to access the electrum wallet.

- Access https://hostname:port/electrum from a browser with the port number specified for the laravel-electrum container.
- Accept a warning on a browser to use a self-signed certificate.
- Click "register" to register name, e-mail address, and password, for the first time. Or click "login" if already registered.
- Access https://hostname:port/electrum again if not redirected automatically.
- Create and load a wallet from a Wallet tab.
- Reload the browser.
- Select one of three tabs (`History`, `Requests`, `Receive`, `Send`, or `Sign) to interact with the wallet.

### Additional note

1. Persistent data

Wallet fils are stored in a Docker volume, which can be examined by the following command.

```
$ docker volume inspect ${WALLET}
```

User registration information is also stored in another Docker volume, as shown below.

```
$ docker volume inspect ${WALLET}-db
```

2. How to run electrum in an (insecure) GUI mode

```
$ xhost +
$ docker run -d -e DISPLAY=${DISPLAY} -v ${HOME}/.Xauthority:/root/.Xauthority:rw -v ${WALLET}:/data -e ELECTRUM_MODE=GUI electrum-daemon
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
