TERMUX_PKG_HOMEPAGE=https://gitlab.gnome.org/GNOME/libxml2/-/wikis/home
TERMUX_PKG_DESCRIPTION="Library for parsing XML documents"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.15.3"
TERMUX_PKG_REVISION=2
TERMUX_PKG_SRCURL="https://download.gnome.org/sources/libxml2/${TERMUX_PKG_VERSION%.*}/libxml2-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=78262a6e7ac170d6528ebfe2efccdf220191a5af6a6cd61ea4a9a9a5042c7a07
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_SETUP_PYTHON=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
	-Ddocs=disabled
	-Dhttp=enabled
	-Dicu=disabled
	-Dlegacy=enabled
	-Dpython=disabled
	-Dhistory=enabled
	-Dreadline=enabled
"
TERMUX_PKG_RM_AFTER_INSTALL="
share/doc/libxml2/html
share/doc/libxml2/xmlcatalog.html
share/doc/libxml2/xmllint.html
"
TERMUX_PKG_DEPENDS="libandroid-glob, libiconv, zlib"
TERMUX_PKG_BUILD_DEPENDS="readline"
TERMUX_PKG_BREAKS="libxml2-dev"
TERMUX_PKG_REPLACES="libxml2-dev"

termux_step_configure() {
	LDFLAGS+=" -landroid-glob"
	export TERMUX_MESON_ENABLE_SOVERSION=1
	termux_step_configure_meson
}

termux_step_post_massage() {
	if ! readelf -d lib/libxml2.so | grep -q '(SONAME).*\[libxml2\.so\.'; then
		termux_error_exit "SONAME for libxml2.so is not properly set."
	fi

	local _SOVERSION=16
	if [[ ! -e "lib/libxml2.so.${_SOVERSION}" ]]; then
		echo "ERROR - Expected: lib/libxml2.so.${_SOVERSION}" >&2
		echo "ERROR - Found   : $(find lib/libxml2* -regex '.*so\.[0-9]+')" >&2
		termux_error_exit "Not proceeding with update."
	fi
}
