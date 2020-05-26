#!/usr/bin/env python3
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

import sys
import os
import platform
from subprocess import check_output

system = platform.system()    
if system != 'Linux':
    print('This script works only on Linux.')
    sys.exit(0)

if len(sys.argv) == 3:
    username = sys.argv[1]
    walletname = sys.argv[2]
    wallet = username + "-" + walletname + "-wallet"
elif len(sys.argv) == 2:
    walletname = sys.argv[1]
    wallet = walletname + "-wallet"
else:    
    print(sys.argv[0] + " [username] walletname")
    print(sys.argv[0] + " -h | --help")
    sys.exit(0)

cmd = "docker inspect --format '{{.State.Pid}}' " + wallet
try:
    root_pid = check_output(cmd, shell=True).rstrip().decode('utf8')
except:
    print("wallet container not found")
    sys.exit(-1)

cmd = "ps -eaf"
processes = check_output(cmd, shell=True).rstrip().decode('utf8').split('\n')

electrum_pid = ''
sh_pid = ''

for process in processes:
    if process.split()[2] == root_pid and process.find("python3 ./run_electrum daemon") != -1:
        electrum_pid = process.split()[1]
        print(electrum_pid)
        sys.exit(0)
    elif process.split()[2] == root_pid and process.find("entrypoint-electrum.sh") != -1:
        sh_pid = process.split()[1]

if sh_pid != '':
    for process in processes:
        if process.split()[2] == sh_pid and process.find("python3 ./run_electrum daemon") != -1:
            electrum_pid = process.split()[1]
            print(electrum_pid)
            sys.exit(0)

print("electrum process not found")



