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
import re
import json as JSON
import platform
import os
from subprocess import check_output

if len(sys.argv) == 3:
    username = sys.argv[1]
    walletname = sys.argv[2]
    wallet = username + "-" + walletname + "-wallet"
elif len(sys.argv) == 2:
    walletname = sys.argv[1]
    wallet = walletname + "-wallet"
else:    
    print(sys.argv[0] + " [username] walletname")
    sys.exit(0)

cmd = "docker inspect --format='{{(index (index .NetworkSettings.Ports \"443/tcp\") 0).HostPort}}' " + wallet
try:
    port = check_output(cmd, shell=True).rstrip().decode('utf8')
except:
    print("wallet container not found " + sys.exc_info()[0])
    sys.exit(-1)

#print("port: " + port)

if os.environ.get('USE_HOSTNAME'):
    cmd = "hostname -f"
    try:
        address = check_output(cmd, shell=True).rstrip().decode('utf8').split()[0]
    except:
        print("wallet address not found " + sys.exc_info()[0])
        sys.exit(-1)
elif os.environ.get('USE_AWS_METADATA'):    
    cmd = "hostname -I"
    try:
        address = check_output(cmd, shell=True).rstrip().decode('utf8').split()[0]
    except:
        print("wallet address not found " + sys.exc_info()[0])
        sys.exit(-1)
    pattern = "^172\."
    if re.search(pattern,address):
        cmd = "curl -s http://169.254.169.254/latest/meta-data/public-ipv4"
        try:
            address = check_output(cmd, shell=True).rstrip().decode('utf8')
        except:
            print("wallet address not found " + sys.exc_info()[0])
            sys.exit(-1)
else:
    cmd = "curl -s http://inet-ip.info/ip"
    try:
        address = check_output(cmd, shell=True).rstrip().decode('utf8')
    except:
        print("wallet address not found " + sys.exc_info()[0])
        sys.exit(-1)
    addresses = address.split(',')
    address = addresses[0]

print("wallet container: " + wallet + " url: https://" + address + ":" + port + "/register")





