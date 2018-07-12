#!/bin/bash

pushd ${HOME}/git/secure-bitcoin-wallet

ARCH=`uname -m`
if [ $ARCH = "x86_64" ]; then
  ARCH="amd64"
fi

images=("python-grpc" "laravel")

for image in "${images[@]}" ; do
    cd $image
    docker build -t $image .
    docker tag $image $REGISTRY/$image-$ARCH
    docker push $REGISTRY/$image-$ARCH
    cd ..
done

popd
