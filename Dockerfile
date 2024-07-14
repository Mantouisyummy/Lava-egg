ARG PYTHON_VERSION=3.12-alpine
ARG OPENJDK_VERSION=22

FROM python:${PYTHON_VERSION}

ENV PYTHONUNBUFFERED=1

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk

ARG OPENJDK_VERSION

RUN apk update && \
    apk add --no-cache \
        bash \
        curl \
        gnupg \
        openssl \
        git \
        tar \
        sqlite \
        fontconfig \
        libstdc++ && \
    mkdir -p /opt/java && \
    curl -L -o /tmp/openjdk.tar.gz "https://api.adoptium.net/v3/binary/latest/${OPENJDK_VERSION}/ga/alpine-linux/x64/jdk/hotspot/normal/eclipse" && \
    tar -xzf /tmp/openjdk.tar.gz -C /opt/java && \
    mv /opt/java/jdk* /opt/java/openjdk && \
    ln -s /opt/java/openjdk/bin/java /usr/local/bin/java && \
    rm /tmp/openjdk.tar.gz && \
    rm -rf /var/cache/apk/*

RUN java -version

RUN pip install --upgrade pip

RUN adduser -D -h /home/container -s /bin/bash container

USER container
ENV USER=container HOME=/home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
