#!/bin/bash
##############################################################################
# Copyright 2020 IBM Corp. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
##############################################################################

DB_VOLUME="/data"
rm $APP_ROOT/database/development.sqlite3
touch $DB_VOLUME/development.sqlite3
ln -s $DB_VOLUME/development.sqlite3 $APP_ROOT/database
chmod 777 $DB_VOLUME/development.sqlite3
chmod 777 $DB_VOLUME

php artisan migrate
php artisan vendor:publish --provider=AraneaDev\Electrum\ElectrumServiceProvider

host=`hostname`

# this is for development runs
# php artisan serve --host=$host

# this is for production runs
echo $host
sed --in-place "s/ServerName localhost/ServerName $host/" /etc/apache2/sites-available/electrum.conf

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
# Set SESSION_COOKIE with the hostname to allow one client browser to access two wallets running on the same HPVS
echo SESSION_COOKIE=$HOSTNAME'_session' >> .env

service apache2 start

# Wait forever
while true; do
  tail -f /dev/null & wait ${!}
done


