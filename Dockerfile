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
    curl \
    ca-certificates \
    fontconfig \
    git \
    gnupg \
    openssl \
    sqlite \
    tar \
    wget \
    && rm -rf /var/cache/apk/*

# Install specified Python version
RUN apk add --no-cache python${PYTHON_VERSION} py3-pip python${PYTHON_VERSION}-venv

# Add AdoptOpenJDK GPG key and repository
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --import - \
    && echo "https://packages.adoptium.net/artifactory/apk/alpine" >> /etc/apk/repositories

# Install specified OpenJDK version
RUN apk update && apk add --no-cache temurin-${OPENJDK_VERSION}-jdk

# Create a symbolic link to set Python path to /usr/local/bin/python
RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python
RUN ln -s /opt/java/openjdk/bin /usr/local/bin

# Create a user and set up home directory
RUN adduser -D -h /home/container -s /bin/bash container

USER container
ENV USER=container HOME=/home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
