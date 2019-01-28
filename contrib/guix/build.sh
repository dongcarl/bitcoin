#!/bin/sh

set -ex

# Make /usr/bin if it doesn't exist
[ -e /usr/bin ] || mkdir -p /usr/bin

# Symlink file to a conventional path
[ -e /usr/bin/file ] || ln -s "$(command -v file)" /usr/bin/file

# Build the depends tree
make -C depends --jobs="$(nproc)"


# Setup a bitcoin with same parameters as gitian
./autogen.sh

CONFIGFLAGS="--enable-glibc-back-compat --enable-reduce-exports --disable-bench --disable-gui-tests"
HOST_CFLAGS="-O2 -g"
HOST_CXXFLAGS="-O2 -g"
HOST_LDFLAGS=-static-libstdc++

env CONFIG_SITE="$(pwd)/depends/x86_64-pc-linux-gnu/share/config.site" \
    ./configure --prefix=/ \
                --disable-ccache \
                --disable-maintainer-mode \
                --disable-dependency-tracking \
                ${CONFIGFLAGS} \
                CFLAGS="${HOST_CFLAGS}" \
                CXXFLAGS="${HOST_CXXFLAGS}" \
                LDFLAGS="${HOST_LDFLAGS}"

# Perform the build
make --jobs="$(nproc)"

# Perform checks
make -C src --jobs="$(nproc)" check-security
make -C src --jobs="$(nproc)" check-symbols

