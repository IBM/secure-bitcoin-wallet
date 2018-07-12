# Python base image with a python binding for grpc using openssl instead of boringssl

FROM python:3.6-slim

# building the grpc from source
WORKDIR /git
ADD patches .
ENV EMBED_OPENSSL false
ENV CFLAGS "-Wno-error"
ENV GRPC_PYTHON_LDFLAGS "-lssl -lcrypto -Lthird_party/openssl-1.0.2f"
RUN apt-get update && \
    apt-get install -y --no-install-recommends git patch make gcc g++ libc-dev libssl-dev autoconf automake libtool wget && \
    git clone --recursive https://github.com/grpc/grpc.git && \
    cd /git/grpc && \
    git checkout v1.12.0 && \
    mv ../*.patch . && \
# patching protobuf to support s390x
    patch -i atomicops_internals_generic_gcc.patch ./third_party/protobuf/src/google/protobuf/stubs/atomicops_internals_generic_gcc.h && \
    git submodule update --init && \
# building the grpc c core library from source
# this also does make run 
    make install && \ 
# installing Cython to build packages for python
    pip3 install Cython && \
# building two static library files for openssl
    cd /git/grpc/tools/openssl && \
    ./use_openssl.sh && \
# installing grpcio package for python
    cd /git/grpc && \
    patch -i setup.py.patch  ./setup.py && \
    patch -i grpc_core_dependencies.py.patch ./src/python/grpcio/grpc_core_dependencies.py && \
    pip3 install -rrequirements.txt && \
    GRPC_PYTHON_BUILD_WITH_CYTHON=1 pip3 install . && \
# installing grpcio-tools package for python
    cd /git/grpc/tools/distrib/python/grpcio_tools && \
    python3 ../make_grpcio_tools.py && \
    GRPC_PYTHON_BUILD_WITH_CYTHON=1 pip3 install . && \
    cd /git && \
    rm -rf grpc
