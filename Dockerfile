ARG PYTHON_VERSION=3.12-alpine
ARG OPENJDK_VERSION=22

FROM python:${PYTHON_VERSION} AS builder

ENV PYTHONUNBUFFERED=1
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
        py3-pandas \
        py3-numpy \
        libstdc++ && \
    mkdir -p /opt/java && \
    curl -L -o /tmp/openjdk.tar.gz "https://api.adoptium.net/v3/binary/latest/${OPENJDK_VERSION}/ga/alpine-linux/x64/jdk/hotspot/normal/eclipse" && \
    tar -xzf /tmp/openjdk.tar.gz -C /opt/java && \
    mv /opt/java/jdk* /opt/java/openjdk && \
    rm /tmp/openjdk.tar.gz && \
    rm -rf /var/cache/apk/*

RUN pip install --upgrade pip

# Create a minimal runtime image
FROM python:${PYTHON_VERSION}

ENV PYTHONUNBUFFERED=1
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

COPY --from=builder /opt/java /opt/java

RUN apk add --no-cache \
        bash \
        sqlite \
        fontconfig \
        py3-pandas \
        git \
        py3-numpy \
        libstdc++

# Verify Java installation
RUN java -version

# Add a non-root user
RUN adduser -D -h /home/container -s /bin/bash container

# Switch to the non-root user
USER container
ENV USER=container HOME=/home/container

# Set working directory
WORKDIR /home/container

# Copy the entrypoint script
COPY ./entrypoint.sh /entrypoint.sh

# Set the entrypoint
CMD ["/bin/bash", "/entrypoint.sh"]
