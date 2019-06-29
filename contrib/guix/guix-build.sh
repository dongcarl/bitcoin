#!/usr/bin/env bash
export LC_ALL=C

set -ex

# Download the depends sources now as we won't have internet access in the build
# container
make -C depends -j"$(nproc)" download ${SOURCES_PATH+SOURCES_PATH="$SOURCES_PATH"}


for host in ${HOSTS=i686-linux-gnu x86_64-linux-gnu arm-linux-gnueabihf aarch64-linux-gnu riscv64-linux-gnu}
do
    # Run the build script 'contrib/guix/build.sh' in the build container
    # specified by 'contrib/guix/manifest.scm'
    guix environment --manifest=contrib/guix/manifest.scm \
                     --load-path=contrib/guix/packages \
                     --container \
                     --pure \
                     --no-cwd \
                     --share=.=/bitcoin \
                     ${SOURCES_PATH+--share="$SOURCES_PATH"} \
                     -- env HOST="$host" \
                     ${SOURCES_PATH+SOURCES_PATH="$SOURCES_PATH"} \
                     REFERENCE_UNIX_TIMESTAMP="$(git log --format=%at -1)" \
                     bash -c "cd /bitcoin && bash contrib/guix/build.sh"
done
