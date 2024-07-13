# Use an official Ubuntu as a parent image for the build stage
FROM ubuntu:22.04 AS build

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Define build arguments
ARG PYTHON_VERSION
ARG OPENJDK_VERSION

# Set ARG variables for the build stage
ARG RELEASE
ARG LAUNCHPAD_BUILD_ARCH

# Install build dependencies
RUN /bin/sh -c set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    wget \
    fontconfig \
    ca-certificates \
    p11-kit \
    binutils \
    tzdata \
    locales \
    dpkg-dev \
    gcc \
    gnupg \
    libbluetooth-dev \
    libbz2-dev \
    libc6-dev \
    libdb-dev \
    libexpat1-dev \
    libffi-dev \
    libgdbm-dev \
    liblzma-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    make \
    tk-dev \
    uuid-dev \
    xz-utils \
    zlib1g-dev; \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen; \
    locale-gen en_US.UTF-8; \
    rm -rf /var/lib/apt/lists/*

# Set environment variables for Java
ENV JAVA_HOME=/opt/java/openjdk

# Set Java version
ENV JAVA_VERSION=jdk-${OPENJDK_VERSION}

# Download and install OpenJDK
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - \
    && add-apt-repository --yes https://packages.adoptium.net/artifactory/deb/ \
    && apt-get update && apt-get install -y \
    temurin-${OPENJDK_VERSION}-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set GPG key for Python
ENV GPG_KEY=7169605F62C751356D054A26A821E680E5FA6305

# Set Python version
ENV PYTHON_VERSION=${PYTHON_VERSION}

# Install build dependencies and compile Python
RUN /bin/sh -c set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    wget; \
    wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
    wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc"; \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY"; \
    gpg --batch --verify python.tar.xz.asc python.tar.xz; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" python.tar.xz.asc; \
    mkdir -p /usr/src/python; \
    tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz; \
    rm python.tar.xz; \
    cd /usr/src/python; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure \
    --build="$gnuArch" \
    --enable-loadable-sqlite-extensions \
    --enable-optimizations \
    --enable-option-checking=fatal \
    --enable-shared \
    --with-lto \
    --with-system-expat \
    --without-ensurepip; \
    nproc="$(nproc)"; \
    EXTRA_CFLAGS="$(dpkg-buildflags --get CFLAGS)"; \
    LDFLAGS="$(dpkg-buildflags --get LDFLAGS)"; \
    LDFLAGS="${LDFLAGS:--Wl},--strip-all"; \
    make -j "$nproc" \
    "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
    "LDFLAGS=${LDFLAGS:-}" \
    "PROFILE_TASK=${PROFILE_TASK:-}"; \
    rm python; \
    make -j "$nproc" \
    "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
    "LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" \
    "PROFILE_TASK=${PROFILE_TASK:-}" \
    python; \
    make install; \
    cd /; \
    rm -rf /usr/src/python; \
    find /usr/local -depth \
    \( \
    \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
    -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
    \) -exec rm -rf '{}' +; \
    ldconfig; \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    python3 --version

# Create symlinks for Python binaries
RUN /bin/sh -c set -eux; \
    for src in idle3 pydoc3 python3 python3-config; do \
    dst="$(echo "$src" | tr -d 3)"; \
    [ -s "/usr/local/bin/$src" ]; \
    [ ! -e "/usr/local/bin/$dst" ]; \
    ln -svT "$src" "/usr/local/bin/$dst"; \
    done

# Set pip version
ENV PYTHON_PIP_VERSION=24.0

# Set pip URL and SHA256
ENV PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/ac00c61f60b2df101b7cdf90ed319b625ac93b42/public/get-pip.py
ENV PYTHON_GET_PIP_SHA256=0f8bb2652c0b0965f268312f49ec21e772d421d381af4324beea66b8acf2635c

# Install pip
RUN /bin/sh -c set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget; \
    wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
    echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum -c -; \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    export PYTHONDONTWRITEBYTECODE=1; \
    python get-pip.py \
    --disable-pip-version-check \
    --no-cache-dir \
    --no-compile \
    "pip==$PYTHON_PIP_VERSION"; \
    rm -f get-pip.py; \
    pip --version

# Use an official Ubuntu as a parent image for the final stage
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Define build arguments
ARG RELEASE
ARG LAUNCHPAD_BUILD_ARCH

# Set environment variables
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV PYTHON_PIP_VERSION=24.0

# Step 0: Set ARG variables
ARG RELEASE
ARG LAUNCHPAD_BUILD_ARCH

# Step 1: Set LABELs for the final image
LABEL org.opencontainers.image.ref.name=ubuntu
LABEL org.opencontainers.image.version=22.04
LABEL author=mantouisyummy maintainer=parker@pterodactyl.io
LABEL org.opencontainers.image.source=https://github.com/pterodactyl/yolks
LABEL org.opencontainers.image.licenses=MIT

# Step 2: Install runtime dependencies and create container user
RUN /bin/sh -c apt-get update -y \
    && apt-get install -y lsof curl ca-certificates openssl git tar sqlite3 fontconfig libfreetype6 tzdata iproute2 libstdc++6 \
    && useradd -d /home/container -m container \
    && rm -rf /var/lib/apt/lists/*

# Step 3: Copy Java and Python from the build stage
COPY --from=build /opt/java/openjdk /opt/java/openjdk
COPY --from=build /usr/local /usr/local

# Step 4: Create and set container user
USER container

# Step 5: Set environment variables for container user
ENV USER=container HOME=/home/container

# Step 6: Set working directory for container user
WORKDIR /home/container

# Step 7: Set stop signal for container
STOPSIGNAL SIGINT

# Step 8: Copy entrypoint script for Java
COPY entrypoint.sh /__cacert_entrypoint.sh

# Step 9: Copy entrypoint script for Python
COPY --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN /bin/sh -c chmod +x /entrypoint.sh

# Step 10: Set entrypoint for container
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]

# Step 11: Set default CMD to entrypoint script
CMD ["/entrypoint.sh"]
