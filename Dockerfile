ARG PYTHON_VERSION=3.12-slim

ARG OPENJDK_VERSION=22

FROM python:${PYTHON_VERSION}

ENV PYTHONUNBUFFERED=1

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk

ARG OPENJDK_VERSION

RUN apt-get update && \
    apt-get install -y wget gnupg2 && \
    apt-get install -y software-properties-common && \
    wget -qO - https://packages.termux.dev/termux-keyring.gpg | apt-key add - && \
    echo "deb https://packages.termux.dev/termux-packages-24 stable main" > /etc/apt/sources.list.d/termux.list && \
    apt-get update && \
    apt-get install -y openjdk-${OPENJDK_VERSION}-jdk && \
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
