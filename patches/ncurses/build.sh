TERMUX_PKG_HOMEPAGE=https://invisible-island.net/ncurses/
TERMUX_PKG_DESCRIPTION="Library for text-based user interfaces in a terminal-independent manner"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
_SNAPSHOT_COMMIT=5f58399b2de47ed14bdfe3a0cb149293b27893d5
TERMUX_PKG_VERSION="6.6.20260307+really6.5.20250830"
TERMUX_PKG_SRCURL="https://github.com/ThomasDickey/ncurses-snapshots/archive/${_SNAPSHOT_COMMIT}.tar.gz"
TERMUX_PKG_SHA256="28cd102efe6a2610e830cc79cf270da6ff0427b2022900a9a36d2761522f9576"
TERMUX_PKG_AUTO_UPDATE=false

TERMUX_PKG_BREAKS="ncurses-dev, ncurses-utils (<< 6.1.20190511-4)"
TERMUX_PKG_REPLACES="ncurses-dev, ncurses-utils (<< 6.1.20190511-4)"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
ac_cv_header_locale_h=no
am_cv_langinfo_codeset=no
--disable-opaque-panel
--disable-stripping
--enable-const
--enable-ext-colors
--enable-ext-mouse
--enable-overwrite
--enable-pc-files
--enable-termcap
--enable-widec
--mandir=$TERMUX_PREFIX/share/man
--without-ada
--without-cxx-binding
--without-debug
--without-tests
--with-normal
--with-pkg-config-libdir=$TERMUX_PREFIX/lib/pkgconfig
--with-static
--with-shared
--with-termpath=$TERMUX_PREFIX/etc/termcap:$TERMUX_PREFIX/share/misc/termcap
"

TERMUX_PKG_RM_AFTER_INSTALL="
share/man/man5
share/man/man7
"

termux_step_pre_configure() {
	MAIN_VERSION="$(cut -f 2 VERSION)"
	PATCH_VERSION="$(cut -f 3 VERSION)"
	ACTUAL_VERSION="${MAIN_VERSION}.${PATCH_VERSION}"
	EXPECTED_VERSION="${TERMUX_PKG_VERSION#*really}"
	if [[ "${ACTUAL_VERSION}" != "${EXPECTED_VERSION}" ]]; then
		termux_error_exit "Version mismatch - expected ${EXPECTED_VERSION}, was ${ACTUAL_VERSION}. Check https://github.com/ThomasDickey/ncurses-snapshots/commit/${_SNAPSHOT_COMMIT}"
	fi
	export CPPFLAGS+=" -fPIC"
}

termux_step_post_make_install() {
	cd "$TERMUX_PREFIX/lib" || termux_error_exit "Prefix 'lib' directory does not exist."

	local version="${TERMUX_PKG_VERSION#*really}"

	for lib in form menu ncurses panel; do
		ln -sfr "lib${lib}w.so.${version:0:3}" "lib${lib}.so.${version:0:3}"
		ln -sfr "lib${lib}w.so.${version:0:3}" "lib${lib}.so.${version:0:1}"
		ln -sfr "lib${lib}w.so.${version:0:3}" "lib${lib}.so"
		ln -sfr "lib${lib}w.a" "lib${lib}.a"
		(cd pkgconfig; ln -sf "${lib}w.pc" "$lib.pc") || termux_error_exit "Failed to install comatibility symlink for '${lib}'"
	done

	for lib in curses termcap tic tinfo; do
		ln -sfr "libncursesw.so.${version:0:3}" "lib${lib}.so.${version:0:3}"
		ln -sfr "libncursesw.so.${version:0:3}" "lib${lib}.so.${version:0:1}"
		ln -sfr "libncursesw.so.${version:0:3}" "lib${lib}.so"
		ln -sfr libncursesw.a "lib${lib}.a"
		(cd pkgconfig; ln -sfr ncursesw.pc "${lib}.pc") || termux_error_exit "Failed to install legacy comatibility symlink for '${lib}'"
	done

	cd "$TERMUX_PREFIX/include/" || termux_error_exit "Prefix 'include' directory does not exist."
	rm -Rf ncurses{,w}
	mkdir ncurses{,w}
	ln -s ../{curses.h,eti.h,form.h,menu.h,ncurses_dll.h,ncurses.h,panel.h,termcap.h,term_entry.h,term.h,unctrl.h} ncurses
	ln -s ../{curses.h,eti.h,form.h,menu.h,ncurses_dll.h,ncurses.h,panel.h,termcap.h,term_entry.h,term.h,unctrl.h} ncursesw

	local TI="$TERMUX_PREFIX/share/terminfo"
	mv "$TI" "$TERMUX_PKG_TMPDIR/full-terminfo"
	mkdir -p "$TI"/{a,d,e,g,n,l,p,r,s,t,v,x}
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/a/ansi "$TI/a/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/d/{dtterm,dumb} "$TI/d/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/e/eterm-color "$TI/e/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/g/gnome{,-256color} "$TI/g/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/n/nsterm "$TI/n/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/l/linux "$TI/l/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/p/putty{,-256color} "$TI/p/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/r/rxvt{,-256color} "$TI/r/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/s/{screen{,2,-256color},st{,-256color}} "$TI/s/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/t/tmux{,-256color} "$TI/t/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/v/vt{52,100,102} "$TI/v/"
	cp "$TERMUX_PKG_TMPDIR"/full-terminfo/x/xterm{,-color,-new,-16color,-256color,+256color} "$TI/x/"
}
