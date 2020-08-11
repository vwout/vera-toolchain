# References:
# - https://github.com/mwarning/docker-openwrt-builder
# - https://github.com/openwrt/archive/tree/aba884cec150a9f4d1de6974a96ff90dff900f79
# - http://wiki.micasaverde.com/index.php/Source_Code
# - https://community.getvera.com/t/where-is-mcvs-openwrt-source/167274/8

# Use Debian 10 'Buster' minimal image as base for building the OpenWRT SDK
FROM debian:buster-slim as openwrt-sdk

RUN apt-get update && \
    apt-get install -y sudo time git-core subversion build-essential g++ bash make libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk flex gettext wget unzip xz-utils python python-distutils-extra \
                       gcc binutils bzip2 perl make grep diffutils libgetoptions-dev libz-dev libc-dev-bin && \
    apt-get clean && \
    useradd -m vera && \
    echo 'vera ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

USER vera
WORKDIR /home/vera

# Get OpenWrt using a similar revision as running on Vera
# Cherry-pick a more recent version of OpenSS (1.0.2j) for DTLS 1.2 support
RUN git clone https://github.com/openwrt/archive.git && \
    cd archive && \
    git checkout aba884cec150a9f4d1de6974a96ff90dff900f79 && \
    rm package/libs/openssl/patches/* && \
    git checkout 2933b2f1224d0274de4e298ee7e6afdb2dbd180e -- package/libs/openssl
    
COPY openwrt/.config archive/

# Copy patches needed to build the OpenWrt toolchain on debian
COPY openwrt/tools archive/tools/
COPY openwrt/toolchain archive/toolchain/

# Copy downloaded files (if any, for caching)
COPY openwrt/dl archive/dl/

RUN cd archive && \
    sudo touch .config && \
    sudo chmod 777 dl && \
    make V=s



# Create a clean toolchain image
FROM debian:buster-slim

# Add required packages
RUN apt-get update && \
    apt-get install -y git cmake libtool autoconf-archive flex && \
    mkdir -p /ramips/packages

COPY --from=openwrt-sdk /home/vera/archive/staging_dir/toolchain-mipsel_24kec+dsp_gcc-4.6-linaro_uClibc-0.9.33.2 /toolchain
COPY --from=openwrt-sdk /home/vera/archive/staging_dir/target-mipsel_24kec+dsp_uClibc-0.9.33.2 /target-rootfs
COPY --from=openwrt-sdk /home/vera/archive/bin/ramips/packages /ramips/packages

ENV STAGING_DIR=/target-rootfs
ENV LUA_VERSION=5.1.5
