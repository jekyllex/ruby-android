# Adapted from: https://github.com/termux/termux-packages/blob/master/scripts/properties.sh
TERMUX_SDK_REVISION=9123335
TERMUX_ANDROID_BUILD_TOOLS_VERSION=33.0.1

: "${TERMUX_NDK_VERSION_NUM:="25"}"
: "${TERMUX_NDK_REVISION:="c"}"
TERMUX_NDK_VERSION=$TERMUX_NDK_VERSION_NUM$TERMUX_NDK_REVISION

: "${TERMUX_JAVA_HOME:=/usr/lib/jvm/java-8-openjdk-amd64}"
export JAVA_HOME=${TERMUX_JAVA_HOME}

if [ "${TERMUX_PACKAGES_OFFLINE-false}" = "true" ]; then
	export ANDROID_HOME=${TERMUX_SCRIPTDIR}/build-tools/android-sdk-$TERMUX_SDK_REVISION
	export NDK=${TERMUX_SCRIPTDIR}/build-tools/android-ndk-r${TERMUX_NDK_VERSION}
else
	: "${ANDROID_HOME:="${HOME}/lib/android-sdk-$TERMUX_SDK_REVISION"}"
	: "${NDK:="${HOME}/lib/android-ndk-r${TERMUX_NDK_VERSION}"}"
fi

TERMUX_APP_PACKAGE="sh.gourav.jekyllex"
TERMUX_REPO_PACKAGE="sh.gourav.jekyllex"
TERMUX_BASE_DIR="/data/data/${TERMUX_APP_PACKAGE}/files"
TERMUX_CACHE_DIR="/data/data/${TERMUX_APP_PACKAGE}/cache"
TERMUX_ANDROID_HOME="${TERMUX_BASE_DIR}/home"
TERMUX_APPS_DIR="${TERMUX_BASE_DIR}/apps"
TERMUX_PREFIX="${TERMUX_BASE_DIR}/usr"

TERMUX_REPO_URL=(
	https://packages-cf.termux.dev/apt/termux-main
	https://packages-cf.termux.dev/apt/termux-root
	https://packages-cf.termux.dev/apt/termux-x11
)

TERMUX_REPO_DISTRIBUTION=(
	stable
	root
	x11
)

TERMUX_REPO_COMPONENT=(
	main
	stable
	main
)

# Allow to override setup.
for f in "${HOME}/.config/termux/termuxrc.sh" "${HOME}/.termux/termuxrc.sh" "${HOME}/.termuxrc"; do
	if [ -f "$f" ]; then
		echo "Using builder configuration from '$f'..."
		. "$f"
		break
	fi
done
unset f