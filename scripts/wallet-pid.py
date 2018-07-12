#!/usr/bin/python3

import sys
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
    print(sys.argv[0] + " -h | --help")
    sys.exit(0)

cmd = "docker inspect " + wallet + " --format '{{.State.Pid}}'"
try:
    ppid = check_output(cmd, shell=True).rstrip().decode('utf8')
except:
    print("wallet container not found")
    sys.exit(-1)

#print("ppid: " + ppid)

cmd = "ps -eaf"
processes = check_output(cmd, shell=True).rstrip().decode('utf8').split('\n')

for process in processes:
    if process.split()[2] == ppid and process.find("python3 electrum daemon") != -1:
        pid = process.split()[1]
        print("wallet container: " + wallet + " pid: " + pid)





