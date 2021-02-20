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

APP_KEY=`grep APP_KEY=base64 .env | sed s/APP_KEY=//`

echo $APP_KEY

sed --in-place "s|'APP_KEY'|'APP_KEY','$APP_KEY'|" config/app.php
sed --in-place "s|'UTC'|'UTC'|" config/app.php

ARCH=
dpkgArch="$(dpkg --print-architecture)"
case "${dpkgArch##*-}" in
    amd64) ARCH='x86_64';;
    ppc64el) ARCH='ppc64le';;
    s390x) ARCH='s390x';;
    arm64) ARCH='arm64';;
    armhf) ARCH='armv7l';;
    i386) ARCH='x86';;
    *) echo "unsupported architecture"; exit 1 ;;
esac
if [ "${ARCH}" = "s390x" ]; then
    TITLE="Secure Bitcoin Wallet on IBM LinuxONE"
else
    TITLE="Bitcoin Wallet on "${ARCH}" Linux"
fi
echo $TITLE

cp .env .env.orig
sed --in-place s/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/ .env
sed --in-place s/DB_HOST=127.0.0.1/\#DB_HOST=127.0.0.1/ .env
sed --in-place s/DB_PORT=3306/\#DB_PORT=3306/ .env
sed --in-place "s|DB_DATABASE=laravel|DB_DATABASE=$APP_ROOT/database/database.sqlite|" .env
sed --in-place s/DB_USERNAME=root/\#DB_USERNAME=root/ .env
sed --in-place s/DB_PASSWORD=/\#DB_PASSWORD=secret/ .env
sed --in-place "s|APP_NAME=Laravel|APP_NAME=\"${TITLE}\"|" .env

diff .env .env.orig

# sed s/right/left/  < resources/views/layouts/app.blade.php > resources/views/layouts/app.blade.php.new
# diff resources/views/layouts/app.blade.php resources/views/layouts/app.blade.php.new
# mv resources/views/layouts/app.blade.php.new resources/views/layouts/app.blade.php

touch $APP_ROOT/database/development.sqlite3
