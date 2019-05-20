(specifications->manifest
 '("bash" ;; useful for debugging, can do with -minimal
   "perl"
   "make"
   "sed"
   "grep"

   ;; native
   "gcc-glibc-2.27@9"
   "glibc@2.27"
   "glibc@2.27:static"
   "binutils"

   ;; x86_64
   "gcc-cross-x86_64-linux-gnu"
   "glibc-cross-x86_64-linux-gnu"
   "glibc-cross-x86_64-linux-gnu:static"
   "binutils-cross-x86_64-linux-gnu"
   ;; aarch64
   "gcc-cross-aarch64-linux-gnu"
   "glibc-cross-aarch64-linux-gnu"
   "glibc-cross-aarch64-linux-gnu:static"
   "binutils-cross-aarch64-linux-gnu"
   ;; armhf
   "gcc-cross-arm-linux-gnueabihf"
   "glibc-cross-arm-linux-gnueabihf"
   "glibc-cross-arm-linux-gnueabihf:static"
   "binutils-cross-arm-linux-gnueabihf"
   ;; ;; i686
   "gcc-cross-i686-linux-gnu"
   "glibc-cross-i686-linux-gnu"
   "glibc-cross-i686-linux-gnu:static"
   "binutils-cross-i686-linux-gnu"
   ;; faketime
   "libfaketime"
   ;; rest
   "zlib"
   "zlib:static"
   "tar"
   "file"
   "gawk"
   "sed"
   "bzip2"
   "bzip2:static"
   "gzip"
   "xz"
   "findutils"
   "diffutils"
   "patch"
   "automake"
   "autoconf"
   "coreutils"
   "which"
   "tcsh"
   "libtool"
   "python@3"
   "pkg-config"
   "util-linux"
   "nss-certs"
   "curl"
   "patchelf"))
