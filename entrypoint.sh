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

export NETWORK="--testnet"
# ENV ELECTRUM_USER electrum
# ENV ELECTRUM_HOME /home/$ELECTRUM_USER
export ELECTRUM_USER=root
export ELECTRUM_HOME=/${ELECTRUM_USER}
export ELECTRUM_PASSWORD=passw0rd
export ZHSM=${ZHSM}
export PYTHONPATH=/git/electrum
export APP_ROOT=/var/www/html/electrum
export ELECTRUM_DAEMON_HOST=localhost

# start an electrum daemon
pushd /git/electrum
./entrypoint-electrum.sh
popd

# start a laravel frontend with apache2
./entrypoint-laravel.sh
