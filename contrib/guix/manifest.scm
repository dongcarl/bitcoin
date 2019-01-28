(use-package-modules
 perl
 gcc
 autotools
 shells
 python
 pkg-config
 linux
 certs
 curl)

(use-modules
 (guix build-system gnu))

(define unwrap-list-or-identity
  ;; Takes a list x, and unwraps the first item if that's the only item, returns
  ;; x unharmed otherwise
  (lambda (x)
    (if (= (length x) 1)
        (car x)
        x)))

(define standard-packages->manifest
  ;; Takes the list of standard packages for the GNU build system and transforms
  ;; it into something understandable by packages->manifest
  (lambda (standard-packages)
    (map unwrap-list-or-identity (map cdr standard-packages))))

(packages->manifest
 `(,perl
   ,automake
   ,autoconf
   ,which
   ,tcsh
   ,libtool
   ,python-2
   ,python
   ,pkg-config
   ,util-linux
   ,nss-certs
   ,@(standard-packages->manifest (standard-packages))
   ,curl))
