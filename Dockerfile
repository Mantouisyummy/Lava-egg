# Use an official Ubuntu as a parent image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk

# Define build arguments
ARG PYTHON_VERSION
ARG OPENJDK_VERSION

# Install dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install specified Python version
RUN add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python${PYTHON_VERSION} \
    python3-pip \
    python${PYTHON_VERSION}-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add AdoptOpenJDK GPG key and repository
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - \
    && add-apt-repository --yes https://packages.adoptium.net/artifactory/deb/

# Install specified OpenJDK version
RUN apt-get update && apt-get install -y \
    temurin-${OPENJDK_VERSION}-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a symbolic link to set Python path to /usr/local/bin/python
RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python
RUN ln -s /opt/java/openjdk/bin /usr/local/bin

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    openssl \
    git \
    tar \
    bash \
    sqlite3 \
    fontconfig \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/container -s /bin/bash container

USER container
ENV  USER=container HOME=/home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
