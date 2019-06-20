

FROM ubuntu:18.04

###################################################################################
# FROM python-grpc/Dockerfile
WORKDIR /git
#ADD python-grpc/patches .
#ENV EMBED_OPENSSL false
#ENV CFLAGS "-Wno-error"
#ENV GRPC_PYTHON_LDFLAGS "-lssl -lcrypto -Lthird_party/openssl-1.0.2f"
RUN apt-get update && \
    apt-get install -y --no-install-recommends git patch make gcc g++ libc-dev libssl-dev autoconf automake libtool wget ca-certificates && \
#    git clone -b v1.13.x https://github.com/grpc/grpc.git && \
#    cd /git/grpc && \
#    git submodule update --init && \
#    mv ../*.patch . && \
# uninstalling existing openssl packages    
#    apt-get remove -y libssl1.1 && \
# building and installing openssl with two static libraries
#    patch -i use_openssl.sh.patch /git/grpc/tools/openssl/use_openssl.sh && \
#    cd /git/grpc/tools/openssl && \
    apt-get install -y wget && \
#    ./use_openssl.sh && \
# patching protobuf to support s390x
#    cd /git/grpc && \
#    patch -i atomicops_internals_generic_gcc.patch ./third_party/protobuf/src/google/protobuf/stubs/atomicops_internals_generic_gcc.h && \
# building the grpc c core library from source
# this also does make run 
#    make install && \
    apt-get install -y --no-install-recommends python3-pip python3-setuptools python3-dev python3-wheel
# installing Cython to build packages for python
#    pip3 install Cython
# installing grpcio package for python
#    cd /git/grpc && \
#    patch -i setup.py.v1.13.x.patch  ./setup.py && \
#    patch -i grpc_core_dependencies.py.v1.13.x.patch ./src/python/grpcio/grpc_core_dependencies.py && \
#    pip3 install -rrequirements.txt && \
#    GRPC_PYTHON_BUILD_WITH_CYTHON=1 pip3 install . && \
# installing grpcio-tools package for python
#    cd /git/grpc/tools/distrib/python/grpcio_tools && \
#    python3 ../make_grpcio_tools.py && \
#    GRPC_PYTHON_BUILD_WITH_CYTHON=1 pip3 install . && \
#    cd /git && \
#    rm -rf grpc


###################################################################################
# FROM electrum/Dockerfile

ARG ELECTRUM_TAG="local-3.1.3-ep11"
#ARG ELECTRUM_TAG="master"

ENV NETWORK "--testnet"
# ENV ELECTRUM_USER electrum
# ENV ELECTRUM_HOME /home/$ELECTRUM_USER
ENV ELECTRUM_USER root
ENV ELECTRUM_HOME /$ELECTRUM_USER
ENV ELECTRUM_PASSWORD passw0rd

# Add user electrum
# RUN adduser --home $ELECTRUM_HOME --uid 2000 --disabled-password --disabled-login $ELECTRUM_USER

WORKDIR /git
ADD electrum/pyep11 /git/pyep11
#RUN apt-get update
RUN apt-get install -y --no-install-recommends protobuf-compiler pyqt5-dev-tools && \
    git clone https://github.com/tnakaike/electrum.git && \
    cd /git/electrum && \
    git checkout ${ELECTRUM_TAG} && \
    pip3 install . && \
    pyrcc5 icons.qrc -o gui/qt/icons_rc.py && \
    protoc --proto_path=lib/ --python_out=lib/ lib/paymentrequest.proto && \
#    pip3 install grpclib && \
#    cd /git/pyep11 && \
#    python3 -m grpc_tools.protoc common/protos/*.proto generated/protos/*.proto \
#        vendor/github.com/gogo/protobuf/gogoproto/*.proto \
#        vendor/github.com/gogo/googleapis/google/api/*.proto \
#        -Icommon/protos -Igenerated/protos \
#	-Ivendor/github.com/gogo/protobuf/gogoproto \
#	-Ivendor/github.com/gogo/googleapis \
#        --python_out=generated/python_grpc --grpc_python_out=generated/python_grpc && \
#    mv /git/pyep11/ep11.py /git/pyep11/pyep11.py /git/pyep11/generated/python_grpc/* /git/electrum && \
    mkdir -p /data && chown ${ELECTRUM_USER} /data

RUN apt-get install -y vim

# Run Electrum as non privileged user
# USER $ELECTRUM_USER

VOLUME /data

EXPOSE 7777

WORKDIR /git/electrum

ADD electrum/entrypoint-load.sh .

ENV ZHSM ${ZHSM}
ENV PYTHONPATH /git/electrum

# CMD ["./entrypoint-load.sh"]



###################################################################################
# FROM laravel/Dockerfile (mostly)

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y php7.2 apache2 curl xz-utils

# install nodejs for php image
# RUN apt-get update
RUN apt-get install -y gnupg git

## Dockerfile for a Node.js docker container from https://github.com/nodejs/docker-node/9/Dockerfile
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Joyent, Inc.
# Copyright (c) 2015 Node.js contributors
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

ENV NODE_VERSION 9.11.1

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.5.1

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

## End of Dockerfile for a Node.js docker container

WORKDIR /root
# ENV APP_ROOT /git/laravel
ENV APP_ROOT /var/www/html/electrum
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
# python2 is required to build dependencies for laravel
# RUN apt-get install -y zlib1g-dev && docker-php-ext-install zip

RUN apt-get install -y sqlite3 libsqlite3-dev libpng-dev libzip-dev python vim php-zip && \
# docker-php-ext-install zip && \
# WORKDIR $APP_ROOT/..
    cd $APP_ROOT/.. && \
    git clone https://github.com/laravel/laravel.git && \
    mv laravel electrum && \
# WORKDIR $APP_ROOT
    cd $APP_ROOT && \
    git checkout v5.4.30

#CMD ["/bin/bash"]


###################################################################################
# FROM laravel-electrum/Dockerfile
RUN apt-get install -y php7.2-mbstring php7.2-xml php7.2-sqlite3

ENV APP_ROOT /var/www/html/electrum

RUN chown -R www-data /var/www
USER www-data

WORKDIR $APP_ROOT

ADD laravel-electrum/composer.json .
ADD laravel-electrum/env.sh .

ARG LARAVEL_ELECTRUM_BRANCH="local-c"
RUN sed "s|dev-local|dev-${LARAVEL_ELECTRUM_BRANCH}|" < composer.json > composer.json.new && \
    mv composer.json.new composer.json && \
    composer -vv install && \
    npm install && \
    mv .env.example .env && \
    php artisan key:generate && \
    ./env.sh && \
    php artisan make:auth && \
    php artisan make:migration create_user && \
    sed "s|App\\\Providers\\\RouteServiceProvider::class,|App\\\Providers\\\RouteServiceProvider::class,\n        AraneaDev\\\Electrum\\\ElectrumServiceProvider::class,|" < config/app.php > config/app.php2 && mv config/app.php2 config/app.php && \
    sed "s|Vue.component('example', require('./components/Example.vue'));|Vue.component('electrum-wallet', require('$APP_ROOT/vendor/araneadev/laravel-electrum/src/resources/assets/js/Electrum.vue'));|" < $APP_ROOT/resources/assets/js/app.js > $APP_ROOT/resources/assets/js/app.js.new && mv   $APP_ROOT/resources/assets/js/app.js.new $APP_ROOT/resources/assets/js/app.js && \
    sed "s/right/left/"  < resources/views/layouts/app.blade.php > resources/views/layouts/app.blade.php.new && \
    mv resources/views/layouts/app.blade.php.new resources/views/layouts/app.blade.php && \
    sed "s/\"nav navbar-nav\"/\"nav navbar-nav navbar-center\"/"  < resources/views/layouts/app.blade.php > resources/views/layouts/app.blade.php.new && \
    mv resources/views/layouts/app.blade.php.new resources/views/layouts/app.blade.php && \
# Change the redict root after login from home to electrum
    sed "s|/home|/electrum|" < app/Http/Controllers/Auth/LoginController.php > app/Http/Controllers/Auth/LoginController.php.new && \
    mv app/Http/Controllers/Auth/LoginController.php.new app/Http/Controllers/Auth/LoginController.php && \
    sed "s|/home|/electrum|" < app/Http/Controllers/Auth/RegisterController.php > app/Http/Controllers/Auth/RegisterController.php.new && \
    mv app/Http/Controllers/Auth/RegisterController.php.new app/Http/Controllers/Auth/RegisterController.php && \
    sed "s|/home|/electrum|" < app/Http/Controllers/Auth/ResetPasswordController.php > app/Http/Controllers/Auth/ResetPasswordController.php.new && \
    mv app/Http/Controllers/Auth/ResetPasswordController.php.new app/Http/Controllers/Auth/ResetPasswordController.php && \
# Use the container hostname as the session key
    sed "s|'laravel_session',|env('HOSTNAME', 'laravel_session'),|" < config/session.php > config/session.php.new && \
    mv config/session.php.new config/session.php && \
    npm install ajv && \
    npm install clipboard --save-dev && \
    npm install moment --save-dev && \
    npm install vue2-bootstrap-modal --save-dev && \
    npm install vue-qrcode-component --save-dev && \
    npm install --save-dev prettier@1.12.0 && \
    npm run dev && \
# set up apache
#RUN chown www-data: -R /var/www/html/electrum/
    chown www-data: -R /var/www/html/electrum/storage && \
    chown www-data: -R /var/www/html/electrum/database

WORKDIR /etc/apache2/sites-available
ADD laravel-electrum/electrum.conf /etc/apache2/sites-available
ADD laravel-electrum/electrum-ssl.conf /etc/apache2/sites-available

#RUN mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.000
ADD laravel-electrum/apache/apache2.conf /etc/apache2

ADD laravel-electrum/electrum.php $APP_ROOT/vendor/araneadev/laravel-electrum/src/config/

WORKDIR $APP_ROOT
ADD laravel-electrum/entrypoint.sh .

VOLUME /data

EXPOSE 443

USER root

ENV ELECTRUM_DAEMON_HOST localhost
ADD entrypoint-unified.sh .

CMD ["./entrypoint-unified.sh"]
