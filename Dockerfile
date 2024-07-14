# Use an official Ubuntu as a parent image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk

# Define build arguments
ARG PYTHON_VERSION=3.12
ARG OPENJDK_VERSION=17

# Install dependencies and specified Python version
RUN apt-get update && \
    apt-get install -y software-properties-common wget gnupg && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-distutils python3-pip && \
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - && \
    add-apt-repository --yes https://packages.adoptium.net/artifactory/deb/ && \
    apt-get update && \
    apt-get install -y temurin-${OPENJDK_VERSION}-jdk && \
    ln -s /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python && \
    ln -s /opt/java/openjdk/bin /usr/local/bin && \
    apt-get install -y curl ca-certificates openssl git tar bash sqlite3 fontconfig --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip using the specific python version
RUN python${PYTHON_VERSION} -m pip install --upgrade pip

# Add a non-root user
RUN useradd -m -d /home/container -s /bin/bash container

# Switch to the non-root user
USER container
ENV USER=container HOME=/home/container

# Set working directory
WORKDIR /home/container

# Copy the entrypoint script
COPY ./entrypoint.sh /entrypoint.sh

# Set the entrypoint
CMD ["/bin/bash", "/entrypoint.sh"]
