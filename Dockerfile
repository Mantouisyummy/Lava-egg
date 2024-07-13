# Use an official Ubuntu as a parent image
FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

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

# Verify installations
RUN python${PYTHON_VERSION} --version \
    && java -version

# Default command
CMD ["python${PYTHON_VERSION}", "--version"]
