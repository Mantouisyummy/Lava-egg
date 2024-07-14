ARG PYTHON_VERSION=3.12-alpine
ARG OPENJDK_VERSION=22

FROM python:${PYTHON_VERSION}

ENV PYTHONUNBUFFERED=1

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk

ARG OPENJDK_VERSION

RUN apk update && \
    apk add --no-cache \
        openjdk${OPENJDK_VERSION} \
        curl \
        ca-certificates \
        openssl \
        git \
        tar \
        bash \
        sqlite \
        fontconfig && \
    ln -s /usr/lib/jvm/java-17-openjdk/bin /usr/local/bin && \
    apk add --no-cache --virtual .build-deps \
        build-base \
        && pip install --upgrade pip \
        && apk del .build-deps && \
    rm -rf /var/cache/apk/*

RUN pip install --upgrade pi

RUN adduser -D -h /home/container -s /bin/bash container

USER container
ENV USER=container HOME=/home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
