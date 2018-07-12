FROM python-grpc

ARG ELECTRUM_TAG="local-3.1.3-ep11"
#ARG ELECTRUM_TAG="master"

ENV NETWORK "--testnet"
# ENV ELECTRUM_USER electrum
# ENV ELECTRUM_HOME /home/$ELECTRUM_USER
ENV ELECTRUM_USER root
ENV ELECTRUM_HOME /$ELECTRUM_USER
ENV ELECTRUM_PASSWORD passw0rd

# Add user electrum
# RUN adduser --home $ELECTRUM_HOME --uid 2000 --disabled-password --disabled-login $ELECTRUM_USER

WORKDIR /git
ADD pyep11 /git
RUN apt-get update && apt-get install -y --no-install-recommends protobuf-compiler pyqt5-dev-tools && \
    git clone https://github.com/tnakaike/electrum.git && \
    cd /git/electrum && \
    git checkout ${ELECTRUM_TAG} && \
    pip3 install . && \
    protoc --proto_path=lib/ --python_out=lib/ lib/paymentrequest.proto && \
    pyrcc5 icons.qrc -o gui/qt/icons_rc.py && \
    mv ../ep11.py ../pyep11.py ../protos . && \
    python3 -m grpc_tools.protoc -I./protos --python_out=. --grpc_python_out=. ./protos/grep11.proto && \
    python3 -m grpc_tools.protoc -I./protos --python_out=. --grpc_python_out=. ./protos/manager.proto && \
    python3 -m grpc_tools.protoc -I./protos --python_out=. --grpc_python_out=. ./protos/server.proto && \
    python3 -m grpc_tools.protoc -I./protos --python_out=. --grpc_python_out=. ./protos/pkcs11.proto && \
    python3 -m grpc_tools.protoc -I./protos --python_out=. --grpc_python_out=. ./protos/discovery.proto && \
    python3 -m grpc_tools.protoc -I./protos --python_out=. --grpc_python_out=. ./protos/keystore.proto && \
    mkdir -p /data && chown ${ELECTRUM_USER} /data

# Run Electrum as non privileged user
# USER $ELECTRUM_USER

VOLUME /data

EXPOSE 7777

WORKDIR /git/electrum

ADD entrypoint-load.sh .

ENV ZHSM ${ZHSM}
ENV PYTHONPATH /git/electrum

CMD ["./entrypoint-load.sh"]
