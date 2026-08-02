#!/usr/bin/env bash
# shellcheck disable=SC2039,SC2059

# Title:         build-bootstrap.sh
# Description:   Build bootstrap archives for JekyllEx from local package
#                sources (termux-packages tree). Based on termux-packages
#                scripts/build-bootstraps.sh (NDK r29 / 16 KB default).
# Usage:         run "build-bootstraps.sh --help"
#
# JekyllEx deltas vs upstream:
# - Package set: coreutils, libxslt, libxml2, unzip, ruby, git, zip (+deps)
# - Output name: ruby-${arch}.zip (jekyllex-android / dl.jekyllex.xyz contract)
# - Layout: TERMUX_PACKAGES_DIRECTORY defaults to Termux docker path
#   /home/builder/termux-packages (override with env if flattening locally)
# - No termux second-stage bootstrap (app installs zip as libN.so itself)
# - --android10 for APK packaging / Android 10+ exec model
#
# Adapted from: https://github.com/termux/termux-packages/blob/23d530425344010b73b0392ab66b041e8f65e34b/scripts/build-bootstraps.sh
version=0.2.0

set -e

export TERMUX_SCRIPTDIR
TERMUX_SCRIPTDIR=$(realpath "$(dirname "$(realpath "$0")")/../")
: "${TERMUX_TOPDIR:="$HOME/.termux-build"}"
# shellcheck source=/dev/null
. "${TERMUX_SCRIPTDIR}/scripts/properties.sh"
# shellcheck source=/dev/null
. "${TERMUX_SCRIPTDIR}/scripts/build/termux_step_handle_buildarch.sh"

BOOTSTRAP_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/ruby-tmp.XXXXXXXX")

BOOTSTRAP_ANDROID10_COMPATIBLE=false

TERMUX_DEFAULT_ARCHITECTURES=("aarch64" "arm" "i686" "x86_64")
TERMUX_ARCHITECTURES=("${TERMUX_DEFAULT_ARCHITECTURES[@]}")

# Match termux-packages docker mount (run-docker.sh → /home/builder/termux-packages).
: "${TERMUX_PACKAGES_DIRECTORY:="/home/builder/termux-packages"}"
TERMUX_BUILT_DEBS_DIRECTORY="$TERMUX_PACKAGES_DIRECTORY/output"
TERMUX_BUILT_PACKAGES_DIRECTORY="/data/data/.built-packages"

IGNORE_BUILD_SCRIPT_NOT_FOUND_ERROR=1
FORCE_BUILD_PACKAGES=0

declare -a PACKAGES=()
declare -a ADDITIONAL_PACKAGES=()
declare -a EXTRACTED_PACKAGES=()
declare -a BUILD_PACKAGE_OPTIONS=()

for cmd in ar awk curl grep gzip find sed tar xargs xz zip; do
	if [ -z "$(command -v $cmd)" ]; then
		echo "[!] Utility '$cmd' is not available in PATH."
		exit 1
	fi
done

build_package() {
	local return_value
	local TERMUX_ARCH="$1"
	local package_name="$2"
	local build_output

	cd "$TERMUX_PACKAGES_DIRECTORY"
	echo $'\n\n\n'"[*] Building '$package_name'..."
	exec 99>&1
	build_output="$("$TERMUX_PACKAGES_DIRECTORY"/build-package.sh "${BUILD_PACKAGE_OPTIONS[@]}" -a "$TERMUX_ARCH" "$package_name" 2>&1 | tee >(cat - >&99); exit ${PIPESTATUS[0]})"
	return_value=$?
	echo "[*] Building '$package_name' exited with exit code $return_value"
	exec 99>&-
	if [ $return_value -ne 0 ]; then
		echo "Failed to build package '$package_name' for arch '$TERMUX_ARCH'" 1>&2
		if [[ $IGNORE_BUILD_SCRIPT_NOT_FOUND_ERROR == "1" ]] && [[ "$build_output" == *"No build.sh script at package dir"* ]]; then
			echo "Ignoring error 'No build.sh script at package dir'" 1>&2
			return 0
		fi
	fi
	return $return_value
}

extract_debs() {
	local package_arch="$1"
	local current_package_name
	local current_package_arch
	local data_archive
	local control_archive
	local package_tmpdir
	local deb
	local file

	cd "$TERMUX_BUILT_DEBS_DIRECTORY"

	if [ -z "$(ls -A)" ]; then
		echo $'\n\n\n'"No debs found"
		return 1
	else
		echo $'\n\n\n'"Deb Files:"
		echo "\""
		ls
		echo "\""
	fi

	for deb in *.deb; do
		current_package_name="$(echo "$deb" | sed -E 's/^([^_]+).*/\1/')"
		current_package_arch="$(echo "$deb" | sed -E 's/.*_(aarch64|all|arm|i686|x86_64)\.deb$/\1/')"
		echo "current_package_name: '$current_package_name'"
		echo "current_package_arch: '$current_package_arch'"

		if [[ "$current_package_arch" != "$package_arch" ]] && [[ "$current_package_arch" != "all" ]]; then
			echo "[*] Skipping incompatible package '$deb' for target '$package_arch'..."
			continue
		fi

		if [[ "$current_package_name" == *"-static" ]]; then
			echo "[*] Skipping static package '$deb'..."
			continue
		fi

		if [[ " ${EXTRACTED_PACKAGES[*]} " == *" $current_package_name "* ]]; then
			echo "[*] Skipping already extracted package '$current_package_name'..."
			continue
		fi

		EXTRACTED_PACKAGES+=("$current_package_name")

		package_tmpdir="${BOOTSTRAP_PKGDIR}/${current_package_name}"
		mkdir -p "$package_tmpdir"
		rm -rf "$package_tmpdir"/*

		echo "[*] Extracting '$deb'..."
		(
			cd "$package_tmpdir"
			ar x "$TERMUX_BUILT_DEBS_DIRECTORY/$deb"

			if [ -f "./data.tar.xz" ]; then
				data_archive="data.tar.xz"
			elif [ -f "./data.tar.gz" ]; then
				data_archive="data.tar.gz"
			else
				echo "No data.tar.* found in '$deb'."
				return 1
			fi

			if [ -f "./control.tar.xz" ]; then
				control_archive="control.tar.xz"
			elif [ -f "./control.tar.gz" ]; then
				control_archive="control.tar.gz"
			else
				echo "No control.tar.* found in '$deb'."
				return 1
			fi

			tar xf "$data_archive" -C "$BOOTSTRAP_ROOTFS"

			if ! ${BOOTSTRAP_ANDROID10_COMPATIBLE}; then
				tar tf "$data_archive" | sed -E -e 's@^\./@/@' -e 's@^/$@/.@' -e 's@^([^./])@/\1@' > "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/info/${current_package_name}.list"

				tar xf "$data_archive"
				find data -type f -print0 | xargs -0 -r md5sum | sed 's@^\.$@@g' > "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/info/${current_package_name}.md5sums"

				tar xf "$control_archive"
				{
					cat control
					echo "Status: install ok installed"
					echo
				} >> "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/status"

				for file in conffiles postinst postrm preinst prerm; do
					if [ -f "${PWD}/${file}" ]; then
						cp "$file" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/info/${current_package_name}.${file}"
					fi
				done
			fi
		)
	done
}

create_bootstrap_archive() {
	echo $'\n\n\n'"[*] Creating 'ruby-${1}.zip'..."
	(
		cd "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}"
		# Keep size down (same as historical jekyllex bootstraps).
		rm -rf ./share/man
		rm -rf ./share/doc
		rm -rf ./share/info
		rm -rf ./share/ri
		rm -rf ./share/locale
		rm -rf ./share/tabset
		rm -rf ./share/aclocal
		rm -rf ./share/terminfo

		while read -r -d '' link; do
			echo "$(readlink "$link")←${link}" >> SYMLINKS.txt
			rm -f "$link"
		done < <(find . -type l -print0)

		zip -r9 "${BOOTSTRAP_TMPDIR}/ruby-${1}.zip" ./*
	)

	mv -f "${BOOTSTRAP_TMPDIR}/ruby-${1}.zip" "$TERMUX_PACKAGES_DIRECTORY/"
	echo "[*] Finished successfully (${1})."
}

set_build_bootstrap_traps() {
	trap 'build_bootstrap_trap' EXIT
	trap 'build_bootstrap_trap TERM' TERM
	trap 'build_bootstrap_trap INT' INT
	trap 'build_bootstrap_trap HUP' HUP
	trap 'build_bootstrap_trap QUIT' QUIT
	return 0
}

build_bootstrap_trap() {
	local build_bootstrap_trap_exit_code=$?
	trap - EXIT
	[ -h "$TERMUX_BUILT_PACKAGES_DIRECTORY" ] && rm -f "$TERMUX_BUILT_PACKAGES_DIRECTORY"
	[ -d "$BOOTSTRAP_TMPDIR" ] && rm -rf "$BOOTSTRAP_TMPDIR"
	[ -n "$1" ] && trap - "$1"
	exit $build_bootstrap_trap_exit_code
}

show_usage() {
	cat <<'HELP_EOF'
build-bootstraps.sh builds JekyllEx ruby bootstraps from a termux-packages tree.

Usage:
  build-bootstraps.sh [command_options]

Options:
  [ -h | --help ]             Display this help
  [ -f ]                      Force rebuild packages
  [ --android10 ]             Android 10+ / APK packaging layout
  [ -a | --add <packages> ]   Extra packages (comma-separated)
  [ --architectures <list> ]  Architectures (comma-separated)

TERMUX_APP_PACKAGE must be xyz.jekyllex (applied via apply-jekyllex-identity.sh).
NDK r29+ links 16 KB-aligned ELFs by default (Termux toolchain_29).

Examples:
  ./scripts/build-bootstraps.sh --android10 --architectures aarch64
  ./scripts/build-bootstraps.sh --android10 -f
HELP_EOF

	echo $'\n'"TERMUX_APP_PACKAGE: \"${TERMUX_APP_PACKAGE:-}\""
	echo "TERMUX_PREFIX: \"${TERMUX_PREFIX:-}\""
	echo "TERMUX_NDK_VERSION: \"${TERMUX_NDK_VERSION:-}\""
	echo "TERMUX_ARCHITECTURES: \"${TERMUX_ARCHITECTURES[*]}\""
}

main() {
	while (($# > 0)); do
		case "$1" in
			-h|--help)
				show_usage
				return 0
				;;
			--android10)
				BOOTSTRAP_ANDROID10_COMPATIBLE=true
				;;
			-a|--add)
				if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
					for pkg in $(echo "$2" | tr ',' ' '); do
						ADDITIONAL_PACKAGES+=("$pkg")
					done
					unset pkg
					shift 1
				else
					echo "[!] Option '--add' requires an argument." 1>&2
					show_usage
					return 1
				fi
				;;
			--architectures)
				if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
					TERMUX_ARCHITECTURES=()
					for arch in $(echo "$2" | tr ',' ' '); do
						TERMUX_ARCHITECTURES+=("$arch")
					done
					unset arch
					shift 1
				else
					echo "[!] Option '--architectures' requires an argument." 1>&2
					show_usage
					return 1
				fi
				;;
			-f)
				BUILD_PACKAGE_OPTIONS+=("-f")
				FORCE_BUILD_PACKAGES=1
				;;
			*)
				echo "[!] Got unknown option '$1'" 1>&2
				show_usage
				return 1
				;;
		esac
		shift 1
	done

	set_build_bootstrap_traps

	for TERMUX_ARCH in "${TERMUX_ARCHITECTURES[@]}"; do
		if [[ " ${TERMUX_DEFAULT_ARCHITECTURES[*]} " != *" $TERMUX_ARCH "* ]]; then
			echo "Unsupported architecture '$TERMUX_ARCH' for in architectures list: '${TERMUX_ARCHITECTURES[*]}'" 1>&2
			echo "Supported architectures: '${TERMUX_DEFAULT_ARCHITECTURES[*]}'" 1>&2
			return 1
		fi
	done

	echo "[*] NDK ${TERMUX_NDK_VERSION} (16 KB page-size alignment is NDK r28+ default)"

	for TERMUX_ARCH in "${TERMUX_ARCHITECTURES[@]}"; do
		termux_step_handle_buildarch

		TERMUX_BUILT_PACKAGES_DIRECTORY_FOR_ARCH="$TERMUX_BUILT_PACKAGES_DIRECTORY-$TERMUX_ARCH"
		mkdir -p "$TERMUX_BUILT_PACKAGES_DIRECTORY_FOR_ARCH"

		if [ -f "$TERMUX_BUILT_PACKAGES_DIRECTORY" ] || [ -d "$TERMUX_BUILT_PACKAGES_DIRECTORY" ]; then
			rm -rf "$TERMUX_BUILT_PACKAGES_DIRECTORY"
		fi
		ln -sf "$TERMUX_BUILT_PACKAGES_DIRECTORY_FOR_ARCH" "$TERMUX_BUILT_PACKAGES_DIRECTORY"

		if [[ $FORCE_BUILD_PACKAGES == "1" ]]; then
			rm -f "$TERMUX_BUILT_PACKAGES_DIRECTORY_FOR_ARCH"/*
			rm -f "$TERMUX_BUILT_DEBS_DIRECTORY"/*
		fi

		BOOTSTRAP_ROOTFS="$BOOTSTRAP_TMPDIR/rootfs-${TERMUX_ARCH}"
		BOOTSTRAP_PKGDIR="$BOOTSTRAP_TMPDIR/packages-${TERMUX_ARCH}"

		if ! ${BOOTSTRAP_ANDROID10_COMPATIBLE}; then
			mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/apt/apt.conf.d"
			mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/apt/preferences.d"
			mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/info"
			mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/triggers"
			mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/updates"
			mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/log/apt"
			touch "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/available"
			touch "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/status"
		fi
		mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/tmp"

		PACKAGES=()
		EXTRACTED_PACKAGES=()

		# JekyllEx bootstrap packages (same set as prior releases).
		PACKAGES+=("coreutils")
		PACKAGES+=("libxslt")
		PACKAGES+=("libxml2")
		PACKAGES+=("unzip")
		PACKAGES+=("ruby")
		PACKAGES+=("git")
		PACKAGES+=("zip")

		for add_pkg in "${ADDITIONAL_PACKAGES[@]}"; do
			if [[ " ${PACKAGES[*]} " != *" $add_pkg "* ]]; then
				PACKAGES+=("$add_pkg")
			fi
		done
		unset add_pkg

		for package_name in "${PACKAGES[@]}"; do
			set +e
			build_package "$TERMUX_ARCH" "$package_name" || return $?
			set -e
		done

		extract_debs "$TERMUX_ARCH" || return $?
		create_bootstrap_archive "$TERMUX_ARCH" || return $?
	done
}

main "$@"
