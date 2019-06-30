(specifications->manifest
 '("bash" ;; useful for debugging, can do with -minimal
   "perl"
   "make"
   "sed"
   "grep"
   ;; toolchains
   "gcc-glibc-2.27-toolchain"
   "x86_64-linux-gnu-toolchain"
   "i686-linux-gnu-toolchain"
   "aarch64-linux-gnu-toolchain"
   "arm-linux-gnueabihf-toolchain"
   "riscv64-linux-gnu-toolchain"
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
   "util-linux"))
