ARG DEBIAN_VERSION=stretch
FROM debian:$DEBIAN_VERSION

ARG ARCH=amd64

RUN dpkg --add-architecture ${ARCH} && \
    apt-get update && apt-get install -y \
    build-essential \
    git wget \
    debhelper devscripts \
    pkg-config \
    liblzma-dev:${ARCH} \
    libssl-dev:${ARCH} \
    libglib2.0-dev:${ARCH}

# To provide support for Raspberry Pi Zero W a toolchain tuned for ARMv6 architecture must be used.
# https://tracker.mender.io/browse/MEN-2399
RUN if [ "${ARCH}" = "armhf" ]; then \
        wget -nc -q https://toolchains.bootlin.com/downloads/releases/toolchains/armv6-eabihf/tarballs/armv6-eabihf--glibc--stable-2018.11-1.tar.bz2 \
        && tar -xjf armv6-eabihf--glibc--stable-2018.11-1.tar.bz2 \
        && rm armv6-eabihf--glibc--stable-2018.11-1.tar.bz2; \
    fi

RUN if [ "${ARCH}" = "arm64" ]; then \
        apt-get install -y gcc-aarch64-linux-gnu; \
    fi

# Golang environment, for cross-compiling the Mender client
ARG GOLANG_VERSION=1.11.5
RUN wget -q https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOPATH "/root/go"
ENV PATH "$PATH:/usr/local/go/bin"

# Copy the debian recipe(s)
COPY recipes /recipes

# Import GPG key, if set
ARG GPG_KEY_BUILD=""
RUN echo $GPG_KEY_BUILD
RUN if [ -n "$GPG_KEY_BUILD" ]; then \
        echo "$GPG_KEY_BUILD" | gpg --import; \
    fi

# Prepare the deb-package script
COPY mender-deb-package /usr/local/bin/
ENTRYPOINT  ["/usr/local/bin/mender-deb-package"]
