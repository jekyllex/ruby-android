TERMUX_PKG_HOMEPAGE=https://git-scm.com/
TERMUX_PKG_DESCRIPTION="Fast, scalable, distributed revision control system"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="Joshua Kahn <tom@termux.dev>"
TERMUX_PKG_VERSION="2.55.0"
TERMUX_PKG_SRCURL=https://mirrors.kernel.org/pub/software/scm/git/git-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=457fdb04dc8728e007d4688695e6912e6f680727920f2a40bf11eacc17505357
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libcurl, libiconv, less, openssl, zlib"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
ac_cv_fread_reads_directories=yes
ac_cv_header_libintl_h=no
ac_cv_iconv_omits_bom=no
ac_cv_snprintf_returns_bogus=no
--with-curl
--with-shell=$TERMUX_PREFIX/bin/sh
"
TERMUX_PKG_EXTRA_MAKE_ARGS="
NO_NSEC=1
NO_PERL=1
NO_EXPAT=1
NO_TCLTK=1
NO_GETTEXT=1
NO_INSTALL_HARDLINKS=1
NO_RUST=1
INSTALL_SYMLINKS=1
CSPRNG_METHOD=openssl
DEFAULT_PAGER=pager
DEFAULT_EDITOR=editor
"
TERMUX_PKG_BUILD_IN_SRC=true

TERMUX_PKG_RM_AFTER_INSTALL="
bin/git-cvsserver
bin/git-shell
libexec/git-core/git-shell
libexec/git-core/git-cvsserver
share/man/man1/git-cvsserver.1
share/man/man1/git-shell.1
"

termux_step_pre_configure() {
	if $TERMUX_ON_DEVICE_BUILD; then
		termux_error_exit "Package '$TERMUX_PKG_NAME' is not safe for on-device builds."
	fi
	rm -Rf $TERMUX_PREFIX/share/git-perl
	CPPFLAGS="-I$TERMUX_PKG_SRCDIR $CPPFLAGS"
}

termux_step_make_install() {
	make -j "${TERMUX_PKG_MAKE_PROCESSES}" ${TERMUX_PKG_EXTRA_MAKE_ARGS} install
}

termux_step_post_make_install() {
	rm -Rf $TERMUX_PREFIX/lib/*-linux*/perl
}

termux_step_post_massage() {
	if [[ ! -f libexec/git-core/git-remote-https ]]; then
		termux_error_exit "Git built without https support"
	fi
}
