#!/usr/bin/env python3

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
    wallet = os.environ['USER'] + "-" + walletname + "-wallet"
else:    
    print(sys.argv[0] + " walletname")
    sys.exit(0)

if platform.machine() == 's390x':
    env = "DOCKER_HOST=tcp://$SSC_HOST:2376 DOCKER_TLS_VERIFY=1 DOCKER_CERT_PATH=/etc/docker/cert.d/$SSC_HOST "
else:
    env = ""

cmd = env + "docker inspect --format='{{(index (index .NetworkSettings.Ports \"443/tcp\") 0).HostPort}}' " + wallet
try:
    port = check_output(cmd, shell=True).rstrip().decode('utf8')
except:
    print("wallet container not found " + sys.exc_info()[0])
    sys.exit(-1)

#print("port: " + port)

if platform.machine() == 's390x':
    address = os.environ['SSC_HOST']
else:
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

print("wallet container: " + wallet + " url: https://" + address + ":" + port + "/register")





