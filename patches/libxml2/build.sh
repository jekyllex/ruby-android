TERMUX_PKG_HOMEPAGE=http://www.xmlsoft.org
TERMUX_PKG_DESCRIPTION="Library for parsing XML documents"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.13.1"
TERMUX_PKG_REVISION=1
_MAJOR_VERSION="${TERMUX_PKG_VERSION%.*}"
TERMUX_PKG_SRCURL=https://download.gnome.org/sources/libxml2/${_MAJOR_VERSION}/libxml2-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=25239263dc37f5f55a5393eff27b35f0b7d9ea4b2a7653310598ea8299e3b741
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--with-legacy
--without-python
"
TERMUX_PKG_RM_AFTER_INSTALL="share/gtk-doc"
TERMUX_PKG_DEPENDS="libiconv, liblzma, zlib"
TERMUX_PKG_BREAKS="libxml2-dev"
TERMUX_PKG_REPLACES="libxml2-dev"

termux_step_pre_configure() {
	# SOVERSION suffix is needed for SONAME of shared libs to avoid conflict
	# with system ones (in /system/lib64 or /system/lib):
	sed -i 's/^\(linux\*android\)\*)/\1-notermux)/' configure
}

termux_step_post_massage() {
	# Check if SONAME is properly set:
	if ! readelf -d lib/libxml2.so | grep -q '(SONAME).*\[libxml2\.so\.'; then
		termux_error_exit "SONAME for libxml2.so is not properly set."
	fi

	local _GUARD_FILE="lib/libxml2.so.2"
	if [ ! -e "${_GUARD_FILE}" ]; then
		termux_error_exit "Error: file ${_GUARD_FILE} not found."
	fi
}