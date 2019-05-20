(define-module (gcc-bitcoin)
  #:use-module ((guix licenses)
                #:select (gpl3+ gpl2+ lgpl2.1+ lgpl2.0+ fdl1.3+))
  #:use-module (gnu packages)
  #:use-module (guix gexp)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages dejagnu)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages base)
  #:use-module (gnu packages cross-base)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages hurd)
  #:use-module (gnu packages mingw)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages perl)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex))

(define-public gcc-glibc-2.27
  (make-gcc-libc gcc-9 glibc-2.27))

(define (make-ssp-fixed-gcc xgcc)
  (package (inherit xgcc)
           (source (origin (inherit (package-source xgcc))
                           (patches
                            (cons
                             (local-file "patches/gcc-i686-ssp.patch")
                             (origin-patches (package-source xgcc))))
                           (modules (origin-modules (package-source xgcc)))
                           (snippet
                            (origin-snippet (package-source xgcc)))))))

(define (make-gcc-rpath-link xgcc)
  (package
   (inherit xgcc)
   (arguments
    (substitute-keyword-arguments (package-arguments xgcc)
      ((#:phases phases)
       `(modify-phases ,phases
          (add-after 'pre-configure 'replace-rpath-with-rpath-link
            (lambda _
              (substitute* (cons "gcc/config/rs6000/sysv4.h"
                                 (find-files "gcc/config"
                                             "^gnu-user.*\\.h$"))
                (("-rpath=") "-rpath-link="))
              #t))))))))

;; x86_64
(define-public xlibc-x86_64
  (cross-libc "x86_64-linux-gnu"
              glibc-2.27))

(define-public xbinutils-x86_64
  (cross-binutils "x86_64-linux-gnu"))

(define-public xgcc-x86_64
  (let ((triplet "x86_64-linux-gnu"))
    (cross-gcc triplet
               #:xgcc (make-ssp-fixed-gcc (make-gcc-rpath-link gcc-9))
               #:xbinutils xbinutils-x86_64
               #:libc xlibc-x86_64)))

;; aarch64
(define-public xlibc-aarch64
  (cross-libc "aarch64-linux-gnu"
              glibc-2.27))

(define-public xbinutils-aarch64
  (cross-binutils "aarch64-linux-gnu"))

(define-public xgcc-aarch64
  (let ((triplet "aarch64-linux-gnu"))
    (cross-gcc triplet
               #:xgcc (make-ssp-fixed-gcc (make-gcc-rpath-link gcc-9))
               #:xbinutils xbinutils-aarch64
               #:libc xlibc-aarch64)))

;; armhf
(define-public xlibc-armhf
  (cross-libc "arm-linux-gnueabihf"
              glibc-2.27))

(define-public xbinutils-armhf
  (cross-binutils "arm-linux-gnueabihf"))

(define-public xgcc-armhf
  (let ((triplet "arm-linux-gnueabihf"))
    (cross-gcc triplet
               #:xgcc (make-ssp-fixed-gcc (make-gcc-rpath-link gcc-9))
               #:xbinutils xbinutils-armhf
               #:libc xlibc-armhf)))

;; i686
(define-public xlibc-i686
  (cross-libc "i686-linux-gnu"
              glibc-2.27))

(define-public xbinutils-i686
  (cross-binutils "i686-linux-gnu"))

(define-public xgcc-i686
  (let ((triplet "i686-linux-gnu"))
    (cross-gcc triplet
               #:xgcc (make-ssp-fixed-gcc (make-gcc-rpath-link gcc-9))
               #:xbinutils xbinutils-i686
               #:libc xlibc-i686)))
