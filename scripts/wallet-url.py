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





