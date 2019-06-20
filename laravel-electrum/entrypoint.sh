#!/bin/bash

DB_VOLUME="/data"
rm $APP_ROOT/database/development.sqlite3
touch $DB_VOLUME/development.sqlite3
ln -s $DB_VOLUME/development.sqlite3 $APP_ROOT/database
chmod 777 $DB_VOLUME/development.sqlite3
chmod 777 $DB_VOLUME

sed "s/$electrumhost = 'electrum-daemon';/$electrumhost = '$ELECTRUM_DAEMON_HOST';/" <  $APP_ROOT/vendor/araneadev/laravel-electrum/src/config/electrum.php > $APP_ROOT/vendor/araneadev/laravel-electrum/src/config/electrum.php.new
diff $APP_ROOT/vendor/araneadev/laravel-electrum/src/config/electrum.php $APP_ROOT/vendor/araneadev/laravel-electrum/src/config/electrum.php.new
mv $APP_ROOT/vendor/araneadev/laravel-electrum/src/config/electrum.php.new $APP_ROOT/vendor/araneadev/laravel-electrum/src/config/electrum.php 

php artisan migrate
php artisan vendor:publish --provider=AraneaDev\Electrum\ElectrumServiceProvider

host=`hostname`

# this is for development runs
# php artisan serve --host=$host

# this is for production runs
echo $host
sed "s/ServerName localhost/ServerName $host/" < /etc/apache2/sites-available/electrum.conf > /etc/apache2/sites-available/electrum.conf.new
diff /etc/apache2/sites-available/electrum.conf /etc/apache2/sites-available/electrum.conf.new
mv /etc/apache2/sites-available/electrum.conf.new /etc/apache2/sites-available/electrum.conf

rm /etc/apache2/sites-available/000-default.conf
rm /etc/apache2/sites-enabled/000-default.conf

a2ensite electrum.conf
a2enmod rewrite

KEY_DIR=/etc/apache2/ssl_keys
mkdir $KEY_DIR
openssl genrsa -out $KEY_DIR/server.key 2048
openssl req -new -key $KEY_DIR/server.key -out $KEY_DIR/server.csr -subj '/C=JP/ST=Tokyo/L=Tokyo/O=Company/OU=Web/CN='$host
openssl x509 -in $KEY_DIR/server.csr -days 365 -req -signkey $KEY_DIR/server.key -out $KEY_DIR/server.crt

a2enmod ssl
a2ensite electrum-ssl.conf

# Tell laravel to use the container hostname as the session key
echo "HOSTNAME=$HOSTNAME" >> .env

service apache2 start

# Wait forever
while true; do
  tail -f /dev/null & wait ${!}
done


