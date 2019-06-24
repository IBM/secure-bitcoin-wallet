#!/usr/bin/env python3

import sys
import os
import platform
from subprocess import check_output

if len(sys.argv) == 3:
    username = sys.argv[1]
    walletname = sys.argv[2]
    wallet = username + "-" + walletname + "-wallet"
elif len(sys.argv) == 2:
    walletname = sys.argv[1]
    wallet = os.environ['USER'] + "-" + walletname + "-wallet"
else:    
    print(sys.argv[0] + " [username] walletname")
    print(sys.argv[0] + " -h | --help")
    sys.exit(0)

if platform.machine() == 's390x':
    env = "DOCKER_HOST=tcp://$SSC_HOST:2376 DOCKER_TLS_VERIFY=1 DOCKER_CERT_PATH=/etc/docker/cert.d/$SSC_HOST "
else:
    env = ""

cmd = env + "docker inspect --format '{{.State.Pid}}' " + wallet
try:
    ppid = check_output(cmd, shell=True).rstrip().decode('utf8')
except:
    print("wallet container not found")
    sys.exit(-1)

#print("ppid: " + ppid)

cmd = "ps -eaf"
processes = check_output(cmd, shell=True).rstrip().decode('utf8').split('\n')

for process in processes:
    if process.split()[2] == ppid and process.find("python3 ./run_electrum daemon") != -1:
        pid = process.split()[1]
        print("wallet container: " + wallet + " pid: " + pid)





