#!/usr/bin/env bash
export LC_ALL=C

set -ex

# Download the depends sources now as we won't have internet access in the build
# container
make -C depends -j48 download

# Run the build script 'contrib/guix/build.sh' in the build container specified
# by 'contrib/guix/manifest.scm'
guix environment --manifest=contrib/guix/manifest.scm --container --pure --no-grafts -- sh contrib/guix/build.sh

# Hack: Remove rpaths from all binaries, and patch their interpreter
for i in src/bitcoind src/bitcoin-cli src/bitcoin-tx src/qt/bitcoin-qt src/test/test_bitcoin
do
        patchelf --remove-rpath "$i"
        interp_path="$(patchelf --print-interpreter "$i")"
        patchelf --set-interpreter "/${interp_path#/*/*/*/}" "$i"
done
