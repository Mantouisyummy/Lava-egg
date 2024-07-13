# Use an official Alpine Linux as a parent image
FROM alpine:3.18

# Set environment variables
ENV JAVA_HOME=/opt/java/openjdk

# Define build arguments
ARG PYTHON_VERSION
ARG OPENJDK_VERSION

# Install dependencies
RUN apk update && apk add --no-cache \
    bash \
    build-base \
    curl \
    ca-certificates \
    fontconfig \
    git \
    gnupg \
    openssl \
    sqlite \
    tar \
    wget \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    ncurses-dev \
    libffi-dev \
    readline-dev \
    tk-dev \
    linux-headers

# Install Python from source
RUN cd /usr/src \
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations \
    && make altinstall \
    && ln -s /usr/local/bin/python${PYTHON_VERSION%.*} /usr/local/bin/python \
    && cd / \
    && rm -rf /usr/src/Python-${PYTHON_VERSION} /usr/src/Python-${PYTHON_VERSION}.tgz

# Add AdoptOpenJDK GPG key and repository
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --import - \
    && echo "https://packages.adoptium.net/artifactory/apk/alpine" >> /etc/apk/repositories

# Install specified OpenJDK version
RUN apk update && apk add --no-cache temurin-${OPENJDK_VERSION}-jdk

# Create a symbolic link to set OpenJDK path to /usr/local/bin
RUN ln -s /opt/java/openjdk/bin /usr/local/bin

# Create a user and set up home directory
RUN adduser -D -h /home/container -s /bin/bash container

USER container
ENV USER=container HOME=/home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
