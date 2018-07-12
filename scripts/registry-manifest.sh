#!/bin/bash

REGISTRY=${REGISTRY:-localhost:5000}

if [ $# != 3 ] ; then
    echo "usage: $0 [DELETE|GET] <IMAGE> <TAG>"
    exit
fi
OP=$1
IMAGE=$2
TAG=$3
if [ ${OP} != "DELETE" ] ; then
    OP="GET"
fi

curl -sSL -I \
     -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
     "https://${REGISTRY}/v2/${IMAGE}/manifests/${TAG}"

digest=`curl -sSL -I \
        -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        "https://${REGISTRY}/v2/${IMAGE}/manifests/${TAG}" \
        | awk '$1 == "Docker-Content-Digest:" { print $2 }' \
        | tr -d $'\r'`
    
echo $digest

echo "https://${REGISTRY}/v2/${IMAGE}/manifests/${digest}"

curl -v -sSL -X ${OP} "https://${REGISTRY}/v2/${IMAGE}/manifests/${digest}"

