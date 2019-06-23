

FROM node:10.16.0-stretch-slim AS node

FROM python:3.7-slim-stretch

COPY --from=node /usr/local /usr/local

WORKDIR /git
ENV GRPC_PYTHON_BUILD_SYSTEM_OPENSSL 1

RUN apt-get update \
	&& mkdir /data \
# installing Docker based on https://docs.docker.com/install/linux/docker-ce/ubuntu
#       && apt-get -y install apt-transport-https ca-certificates curl software-properties-common
        && apt-get -y install ca-certificates curl \
# install python and other additional packages
        && apt-get install -y --no-install-recommends git python3-pip python3-dev build-essential python3-setuptools python3-wheel protobuf-compiler libssl-dev libffi-dev autoconf automake libtool vim \
# building the grpc c core library from source
        && git clone -b v1.20.x https://github.com/grpc/grpc.git \
        && cd /git/grpc \
        && git submodule update --init \
        && make install \
# installing Cython to build packages for python
        && pip3 install Cython \
# installing grpcio package for python
        && cd /git/grpc \
        && pip3 install -rrequirements.txt \
        && GRPC_PYTHON_BUILD_WITH_CYTHON=1 pip3 install . \
# installing grpcio-tools package for python
        && cd /git/grpc/tools/distrib/python/grpcio_tools \
        && python3 ../make_grpcio_tools.py \
        && GRPC_PYTHON_BUILD_WITH_CYTHON=1 pip3 install . \
# clean up
        && apt-get -y autoremove && apt-get clean \
        && rm -rf /git/grpc
#       && rm -rf /var/lib/apt/lists/* /var/tmp/* /git/grpc

###################################################################################
# FROM electrum/Dockerfile

ARG ELECTRUM_TAG="local-3.3.6-ep11"
#ARG ELECTRUM_TAG="local-3.1.3-ep11"
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
ADD pyep11 /git/pyep11
RUN  git clone https://github.com/tnakaike/electrum.git && \
    cd /git/electrum && \
    git checkout ${ELECTRUM_TAG} && \
    pip3 install . && \
#   pyrcc5 icons.qrc -o gui/qt/icons_rc.py && \
#   protoc --proto_path=lib/ --python_out=lib/ lib/paymentrequest.proto && \
    protoc --proto_path=electrum --python_out=electrum electrum/paymentrequest.proto && \
    pip3 install grpclib && \
    cd /git/pyep11 && \
    python3 -m grpc_tools.protoc common/protos/*.proto generated/protos/*.proto \
        vendor/github.com/gogo/protobuf/gogoproto/*.proto \
        vendor/github.com/gogo/googleapis/google/api/*.proto \
        -Icommon/protos -Igenerated/protos \
	-Ivendor/github.com/gogo/protobuf/gogoproto \
	-Ivendor/github.com/gogo/googleapis \
        --python_out=/git/pyep11/generated/python_grpc --grpc_python_out=/git/pyep11/generated/python_grpc \
	&& mv /git/pyep11/generated/python_grpc/* /git/electrum \
	&& mv /git/pyep11/ep11.py /git/electrum && \
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
RUN apt-get install -y php apache2 curl xz-utils

# install nodejs for php image
# RUN apt-get update
RUN apt-get install -y gnupg git

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

RUN apt-get install -y php-mbstring php-xml php-sqlite3

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
