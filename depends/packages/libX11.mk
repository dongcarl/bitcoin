package=libX11
$(package)_version=1.6.2
$(package)_download_path=https://xorg.freedesktop.org/releases/individual/lib/
$(package)_file_name=$(package)-$($(package)_version).tar.bz2
$(package)_sha256_hash=2aa027e837231d2eeea90f3a4afe19948a6eb4c8b2bec0241eba7dbc8106bd16
$(package)_dependencies=libxcb xtrans xextproto xproto

define $(package)_set_vars
  # A number of steps in the autoconfig process implicitly assume that the build
  # system and the host system are the same. For example, library components
  # want to build and run test programs to determine the behavior of certain
  # host system elements. This is clearly impossible when crosscompiling. To
  # work around these issues, the --enable-malloc0returnsnull (or
  # --disable-malloc0returnsnull, depending on the host system) must be passed
  # to configure.
  #                                -- https://www.x.org/wiki/CrossCompilingXorg/
  #
  # XORG_CHECK_MALLOC_ZERO from xorg-macros was changed to use the autoconf
  # cache, expecting cross-compilation environments to seed this cache as there
  # is no single correct value when cross compiling (think uclibc, musl, etc.).
  # You can see the actual change in commit 72fdc868b56fe2b7bdc9a69872651baeca72
  # in the freedesktop/xorg-macros repo.
  #
  # As a result of this change, if we don't seed the cache and we don't use
  # either --{en,dis}able-malloc0returnsnull, the AC_RUN_IFELSE block has no
  # optional action-if-cross-compiling argument and configure prints an error
  # message and exits as documented in the autoconf manual. Prior to this
  # commit, the AC_RUN_IFELSE block had an action-if-cross-compiling argument
  # which set the more pessimistic default value MALLOC_ZERO_RETURNS_NULL=yes.
  $(package)_config_opts=--disable-xkb --disable-static --disable-malloc0returnsnull
  $(package)_config_opts_linux=--with-pic
endef

define $(package)_preprocess_cmds
  cp -f $(BASEDIR)/config.guess $(BASEDIR)/config.sub .
endef

define $(package)_config_cmds
  $($(package)_autoconf)
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install
endef

define $(package)_postprocess_cmds
  rm lib/*.la
endef
