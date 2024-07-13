# Use an official Ubuntu as a parent image
FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Define build arguments
ARG PYTHON_VERSION
ARG OPENJDK_VERSION

# Set environment variables for Java and Python paths
ENV JAVA_HOME=/opt/java/openjdk
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Combine the PATH environment variables for OpenJDK and Python
ENV PATH=/opt/java/openjdk/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# Install base dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget \
    gnupg \
    tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install specified Python version
RUN add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python${PYTHON_VERSION} \
    python3-pip \
    python${PYTHON_VERSION}-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python

# Add AdoptOpenJDK GPG key and repository and install specified OpenJDK version
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - \
    && add-apt-repository --yes https://packages.adoptium.net/artifactory/deb/ \
    && apt-get update && apt-get install -y \
    temurin-${OPENJDK_VERSION}-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user and set working directory
RUN useradd -d /home/container -m container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Setup entrypoint script
COPY --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Define the entrypoint and command
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
