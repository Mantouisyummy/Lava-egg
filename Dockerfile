ARG PYTHON_VERSION=3.12-alpine
ARG OPENJDK_VERSION=21.0.4+7

FROM python:${PYTHON_VERSION}

ARG PYTHON_VERSION
ARG OPENJDK_VERSION

ENV PYTHONUNBUFFERED=1
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN apk add --update --no-cache \
    bash \
    curl \
    openssl \
    git \
    gcc \
    build-base \
    musl-dev \
    python3-dev \
    tar \
    libstdc++ && \
    mkdir -p /opt/java && \
    export major_version=$(echo "$OPENJDK_VERSION" | cut -d '.' -f 1) && \
    export modified_version=${OPENJDK_VERSION//+/_} && \
    curl -L -o /tmp/openjdk.tar.gz "https://github.com/adoptium/temurin${major_version}-binaries/releases/download/jdk-${OPENJDK_VERSION}/OpenJDK${major_version}U-jre_x64_alpine-linux_hotspot_${modified_version}.tar.gz" && \
    tar -xzf /tmp/openjdk.tar.gz -C /opt/java && \
    mv /opt/java/jdk* /opt/java/openjdk && \
    rm /tmp/openjdk.tar.gz && \
    pip install --upgrade pip

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
