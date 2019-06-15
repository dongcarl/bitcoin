#!/usr/bin/env bash
export LC_ALL=C

set -e -x -o pipefail

if [ -z "$HOST" ]
then
    echo '$HOST: Environment variable not set.' >&2
    exit 1
fi

# Guix-specific environment variables
export GUIX_LD_WRAPPER_DISABLE_RPATH=yes

CROSS_GLIBC="$(grep -E "/\S+glibc-cross-$HOST-[^-]+\\\"" "$GUIX_ENVIRONMENT/manifest" | sed -E -e 's|^\s+"||g' -e 's|"\s*$||g')"
CROSS_GLIBC_STATIC="$(grep -E "/\S+glibc-cross-$HOST-[^-]+-static" "$GUIX_ENVIRONMENT/manifest" | sed -E -e 's|^\s+"||g' -e 's|"\s*$||g')"
CROSS_KERNEL="$(grep -E "/\S+linux-libre-headers-cross-$HOST" "$GUIX_ENVIRONMENT/manifest" | head -n1 | sed -E -e 's|^\s+"||g' -e 's|"\s*$||g')"
CROSS_GCC="$(grep -E "/\S+gcc-cross-$HOST" "$GUIX_ENVIRONMENT/manifest" | sed -E -e 's|^\s+"||g' -e 's|"\s*$||g')"

export CROSS_C_INCLUDE_PATH="${CROSS_GCC}/include:${CROSS_GLIBC}/include:${CROSS_KERNEL}/include"
export CROSS_CPLUS_INCLUDE_PATH="${CROSS_GCC}/include/c++:${CROSS_GLIBC}/include:${CROSS_KERNEL}/include"
export CROSS_LIBRARY_PATH="${CROSS_GLIBC}/lib:${CROSS_GLIBC_STATIC}/lib:${CROSS_GCC}/lib:${CROSS_GCC}/${HOST}/lib:${CROSS_KERNEL}/lib"

# Make /usr/bin if it doesn't exist
[ -e /usr/bin ] || mkdir -p /usr/bin

# Symlink file to a conventional path
[ -e /usr/bin/file ] || ln -s "$(command -v file)" /usr/bin/file
[ -e /usr/bin/env ]  || ln -s "$(command -v env)"  /usr/bin/env

# Emulate Gitian reference date time logic
if [ -z "$REFERENCE_UNIX_TIMESTAMP" ]
then
    echo '$REFERENCE_UNIX_TIMESTAMP: Environment variable not set.' >&2
    exit 1
fi
REFERENCE_DATE="$(date --date="@${REFERENCE_UNIX_TIMESTAMP}" +'%F')"
export REFERENCE_DATE
REFERENCE_TIME="$(date --date="@${REFERENCE_UNIX_TIMESTAMP}" +'%T')"
export REFERENCE_TIME
export REFERENCE_DATETIME="${REFERENCE_DATE} ${REFERENCE_TIME}"

# Setup an output directory
OUTDIR="${PWD}/output"
mkdir -p "${OUTDIR}"

# Environment variables for determism
export QT_RCC_TEST=1
export QT_RCC_SOURCE_DATE_OVERRIDE=1
export TAR_OPTIONS="--owner=0 --group=0 --numeric-owner --mtime='@${REFERENCE_UNIX_TIMESTAMP}' --sort=name"
export TZ="UTC"

# Let's ground ourselves
BASEPREFIX="${PWD}/depends"

# Faketime Wrapping

# Setup wrapped binary path
WRAP_DIR="${HOME}/wrapped"
mkdir -p "${WRAP_DIR}"

# Wrap GZIP as environment variable is deprecated
cat > "${WRAP_DIR}/gzip" <<EOF
#!/usr/bin/env bash
REAL="$(command -v gzip)"
"\$REAL" -9n \$@
EOF
chmod +x "${WRAP_DIR}/gzip"

# Declare binaries to wrap
FAKETIME_HOST_PROGS="gcc g++"
FAKETIME_PROGS="date ar ranlib nm"

create_faketime_wrapper() {
    faketime="$1"
    prog="$2"
    wrapped="${WRAP_DIR}/${prog}"
cat > "$wrapped" <<EOF
#!/usr/bin/env bash
REAL="$(which -a "${prog}" | grep -v "${wrapped}" | head -1)"
export LD_PRELOAD="${GUIX_ENVIRONMENT}/lib/faketime/libfaketime.so.1"
export FAKETIME="${faketime}"
"\$REAL" \$@
EOF
    chmod +x "$wrapped"
}

create_global_faketime_wrappers() {
    for prog in ${FAKETIME_PROGS}; do
        create_faketime_wrapper "$1" "$prog"
    done
}

create_perhost_faketime_wrappers() {
    for prog in ${FAKETIME_HOST_PROGS}; do
        host_prog="${1}-${prog}"
        if command -v "${host_prog}"
        then
            create_faketime_wrapper "$2" "$host_prog"
        else
            echo "${host_prog}: Failed to create per-host faketime wrapper as program doesn't exist in path" >&2
            exit 1
        fi
    done
}

# Faketime for depends, arbitrary time
export PATH_orig="${PATH}"
create_global_faketime_wrappers "2000-01-01 12:00:00"
create_perhost_faketime_wrappers "${HOST}" "2000-01-01 12:00:00"
export PATH="${WRAP_DIR}:${PATH}"


# Build the depends tree
make -C depends --jobs="$(nproc)" HOST="${HOST}" \
                                  ${SOURCES_PATH+SOURCES_PATH="$SOURCES_PATH"} \
                                  i686_linux_CC=i686-linux-gnu-gcc \
                                  i686_linux_CXX=i686-linux-gnu-g++ \
                                  i686_linux_AR=i686-linux-gnu-ar \
                                  i686_linux_RANLIB=i686-linux-gnu-ranlib \
                                  i686_linux_NM=i686-linux-gnu-nm \
                                  i686_linux_STRIP=i686-linux-gnu-strip \
                                  x86_64_linux_CC=x86_64-linux-gnu-gcc \
                                  x86_64_linux_CXX=x86_64-linux-gnu-g++ \
                                  x86_64_linux_AR=x86_64-linux-gnu-ar \
                                  x86_64_linux_RANLIB=x86_64-linux-gnu-ranlib \
                                  x86_64_linux_NM=x86_64-linux-gnu-nm \
                                  x86_64_linux_STRIP=x86_64-linux-gnu-strip

# Faketime for binaries, based on $REFERENCE_UNIX_TIMESTAMP
export PATH="${PATH_orig}"
create_global_faketime_wrappers "${REFERENCE_DATETIME}"
create_perhost_faketime_wrappers "${HOST}" "${REFERENCE_DATETIME}"
export PATH="${WRAP_DIR}:${PATH}"


# Create the source tarball if not already at "${OUTDIR}/src"
if [[ -z $(find "${OUTDIR}/src" -name 'bitcoin-*.tar.gz') ]]; then
    ./autogen.sh
    env CONFIG_SITE="${BASEPREFIX}/${HOST}/share/config.site" ./configure --prefix=/
    make dist GZIP_ENV='-9n'
    SOURCEDIST="$(find "${PWD}" -name 'bitcoin-*.tar.gz')"
else
    SOURCEDIST="$(find "${OUTDIR}/src" -name 'bitcoin-*.tar.gz')"
fi

BASESOURCEDIST="$(basename "${SOURCEDIST}")"
DISTNAME="${BASESOURCEDIST%.tar.gz}"

glibc-dynamic-linker() {
    case "$1" in
        i686-linux-gnu)
            echo /lib/ld-linux.so.2
            ;;
        x86_64-linux-gnu)
            echo /lib64/ld-linux-x86-64.so.2
            ;;
        arm-linux-gnueabihf)
            echo /lib/ld-linux-armhf.so.3
            ;;
        aarch64-linux-gnu)
            echo /lib/ld-linux-aarch64.so.1
            ;;
        riscv64-linux-gnu)
            echo /lib/ld-linux-riscv64-lp64d.so.1
            ;;
        *)
            echo no-ld.so
            ;;
    esac
}

# Setup a bitcoin with same parameters as gitian
SPECS="-specs=${PWD}/contrib/guix/fix-ssp.spec"
CONFIGFLAGS="--enable-glibc-back-compat --enable-reduce-exports --disable-bench --disable-gui-tests"
HOST_CFLAGS="-O2 -g ${SPECS} -ffile-prefix-map=${PWD}=."
HOST_CXXFLAGS="-O2 -g ${SPECS} -ffile-prefix-map=${PWD}=."
HOST_LDFLAGS="-Wl,--as-needed -Wl,--dynamic-linker=$(glibc-dynamic-linker "$HOST") -static-libstdc++"

export PATH="${BASEPREFIX}/${HOST}/native/bin:${PATH}"
mkdir -p "distsrc-${HOST}"
(
    # Extract the source tarball
    cd "distsrc-${HOST}"
    INSTALLPATH="${PWD}/installed/${DISTNAME}"
    mkdir -p "${INSTALLPATH}"
    tar --strip-components=1 -xf "${SOURCEDIST}"

    env CONFIG_SITE="${BASEPREFIX}/${HOST}/share/config.site" \
        ./configure --prefix=/ \
                    --disable-ccache \
                    --disable-maintainer-mode \
                    --disable-dependency-tracking \
                    ${CONFIGFLAGS} \
                    CFLAGS="${HOST_CFLAGS}" \
                    CXXFLAGS="${HOST_CXXFLAGS}" \
                    LDFLAGS="${HOST_LDFLAGS}"

    sed -i.old 's/-lstdc++ //g' config.status libtool src/univalue/config.status src/univalue/libtool

    # Perform the build
    make --jobs="$(nproc)" V=1

    # Perform checks
    make -C src --jobs=1 check-security
    make -C src --jobs=1 check-symbols

    make install DESTDIR="${INSTALLPATH}"
    (
        cd installed
        find . -name "lib*.la" -delete
        find . -name "lib*.a" -delete

        rm -rf "${DISTNAME}/lib/pkgconfig"

        find "${DISTNAME}/bin" -type f -executable -print0 \
            | xargs -0 -n1 -I{} ../contrib/devtools/split-debug.sh {} {} {}.dbg
        find "${DISTNAME}/lib" -type f -print0 \
            | xargs -0 -n1 -I{} ../contrib/devtools/split-debug.sh {} {} {}.dbg

        cp ../doc/README.md "${DISTNAME}/"

        find "${DISTNAME}" -not -name "*.dbg" -print0 \
            | sort --zero-terminated \
            | tar --create --no-recursion --mode='u+rw,go+r-w,a+X' --null --files-from=- \
            | gzip > "${OUTDIR}/${DISTNAME}-${HOST}.tar.gz"

        find "${DISTNAME}" -name "*.dbg" -print0 \
            | sort --zero-terminated \
            | tar --create --no-recursion --mode='u+rw,go+r-w,a+X' --null --files-from=- \
            | gzip > "${OUTDIR}/${DISTNAME}-${HOST}-debug.tar.gz"
    )
)

# Move source tarball to well-known path
mkdir -p "${OUTDIR}/src"
mv -n "$SOURCEDIST" "${OUTDIR}/src"
