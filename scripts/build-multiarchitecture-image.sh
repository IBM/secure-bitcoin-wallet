#!/bin/bash

# this script builds a multiarchitecture image for s390x (LinuxONE) and amd64 (x86_64)

REGISTRY=${REGISTRY:-localhost:5000}

if [ $# != 1 ] ; then
    echo "usage: $0 <IMAGE>"
    exit
fi
IMAGE=$1

archs=("s390x" "amd64")
images=""

for arch in "${archs[@]}" ; do
    docker pull $REGISTRY/$IMAGE-$arch
    images=$images" "$REGISTRY/$IMAGE-$arch
done

echo $images
docker manifest create $REGISTRY/$IMAGE $images --amend

#docker manifest inspect $REGISTRY/$IMAGE:$USER

for arch in "${archs[@]}" ; do
    docker manifest annotate $REGISTRY/$IMAGE $REGISTRY/$IMAGE-$arch --arch $arch --os linux
done

docker manifest inspect $REGISTRY/$IMAGE

docker manifest push $REGISTRY/$IMAGE

for arch in "${archs[@]}" ; do
    docker rmi $REGISTRY/$IMAGE-$arch
done


