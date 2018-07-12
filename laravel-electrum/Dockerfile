FROM laravel

ENV APP_ROOT /var/www/html/electrum

WORKDIR $APP_ROOT

ADD composer.json .
ADD env.sh .

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
ADD electrum.conf /etc/apache2/sites-available
ADD electrum-ssl.conf /etc/apache2/sites-available

#RUN mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.000
ADD apache/apache2.conf /etc/apache2

ADD electrum.php $APP_ROOT/vendor/araneadev/laravel-electrum/src/config/

WORKDIR $APP_ROOT
ADD entrypoint.sh .

VOLUME /data

EXPOSE 443

CMD ["./entrypoint.sh"]