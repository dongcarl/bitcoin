packages:=boost libevent

qt_packages = zlib

qrencode_packages = qrencode

qt_linux_packages:=qt expat libxcb xcb_proto libXau xproto freetype fontconfig
qt_android_packages=qt

rapidcheck_packages = rapidcheck

qt_darwin_packages=qt
qt_mingw32_packages=qt

wallet_packages=bdb

zmq_packages=zeromq

upnp_packages=miniupnpc

darwin_native_packages = native_biplist native_ds_store native_mac_alias

ifneq ($(build_os),darwin)
ifeq ($(strip $(FORCE_USE_SYSTEM_CLANG)),)
darwin_native_packages += native_cctools
else
darwin_native_packages += native_cctools-system-clang
endif
darwin_native_packages += native_cdrkit native_libdmg-hfsplus
endif
