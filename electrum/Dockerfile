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
ADD pyep11 /git/pyep11
RUN apt-get update && apt-get install -y --no-install-recommends protobuf-compiler pyqt5-dev-tools && \
    git clone https://github.com/tnakaike/electrum.git && \
    cd /git/electrum && \
    git checkout ${ELECTRUM_TAG} && \
    pip3 install . && \
    pyrcc5 icons.qrc -o gui/qt/icons_rc.py && \
    protoc --proto_path=lib/ --python_out=lib/ lib/paymentrequest.proto && \
    pip3 install grpclib && \
    cd /git/pyep11 && \
    python3 -m grpc_tools.protoc common/protos/*.proto generated/protos/*.proto \
        vendor/github.com/gogo/protobuf/gogoproto/*.proto \
        vendor/github.com/gogo/googleapis/google/api/*.proto \
        -Icommon/protos -Igenerated/protos \
	-Ivendor/github.com/gogo/protobuf/gogoproto \
	-Ivendor/github.com/gogo/googleapis \
        --python_out=generated/python_grpc --grpc_python_out=generated/python_grpc && \
    mv /git/pyep11/ep11.py /git/pyep11/pyep11.py /git/pyep11/generated/python_grpc/* /git/electrum && \
    mkdir -p /data && chown ${ELECTRUM_USER} /data

RUN apt-get install -y vim

# Run Electrum as non privileged user
# USER $ELECTRUM_USER

VOLUME /data

EXPOSE 7777

WORKDIR /git/electrum

ADD entrypoint-load.sh .

ENV ZHSM ${ZHSM}
ENV PYTHONPATH /git/electrum

CMD ["./entrypoint-load.sh"]
