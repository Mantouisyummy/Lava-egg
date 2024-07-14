ARG PYTHON_VERSION=3.12-slim

ARG OPENJDK_VERSION=22

FROM python:${PYTHON_VERSION}

ENV PYTHONUNBUFFERED=1

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk

ARG OPENJDK_VERSION

RUN apt-get update && \
    apt-get install -y software-properties-common curl gnupg && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - && \
    add-apt-repository --yes https://packages.adoptium.net/artifactory/deb/ && \
    apt-get update && \
    apt-get install -y temurin-${OPENJDK_VERSION}-jdk && \
    ln -s /opt/java/openjdk/bin /usr/local/bin && \
    apt-get install -y curl ca-certificates openssl git tar bash sqlite3 fontconfig --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN java -version

RUN pip install --upgrade pip && \
    pip --version

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
