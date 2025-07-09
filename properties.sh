# Adapted from: https://github.com/termux/termux-packages/blob/acf1df1e90034ce0100ac54726ae56792bf56859/scripts/properties.sh
TERMUX_SDK_REVISION=9123335
TERMUX_ANDROID_BUILD_TOOLS_VERSION=33.0.1

: "${TERMUX_NDK_VERSION_NUM:="27"}"
: "${TERMUX_NDK_REVISION:=""}"
TERMUX_NDK_VERSION=$TERMUX_NDK_VERSION_NUM$TERMUX_NDK_REVISION

if [ -z "${JAVA_HOME}" ]; then
  : "${TERMUX_JAVA_HOME:=/usr/lib/jvm/java-17-openjdk-amd64}"
  export JAVA_HOME="${TERMUX_JAVA_HOME}"
else
  : "${TERMUX_JAVA_HOME:="${JAVA_HOME}"}"
fi

if [ "${TERMUX_PACKAGES_OFFLINE-false}" = "true" ]; then
	export ANDROID_HOME=${TERMUX_SCRIPTDIR}/build-tools/android-sdk-$TERMUX_SDK_REVISION
	export NDK=${TERMUX_SCRIPTDIR}/build-tools/android-ndk-r${TERMUX_NDK_VERSION}
else
	: "${ANDROID_HOME:="${HOME}/lib/android-sdk-$TERMUX_SDK_REVISION"}"
	: "${NDK:="${HOME}/lib/android-ndk-r${TERMUX_NDK_VERSION}"}"
fi

# Termux packages configuration.
TERMUX_APP_PACKAGE="xyz.jekyllex"
TERMUX_REPO_PACKAGE="xyz.jekyllex"
TERMUX_BASE_DIR="/data/data/${TERMUX_APP_PACKAGE}/files"
TERMUX_CACHE_DIR="/data/data/${TERMUX_APP_PACKAGE}/cache"
TERMUX_ANDROID_HOME="${TERMUX_BASE_DIR}/home"
TERMUX_APPS_DIR="${TERMUX_BASE_DIR}/apps"
TERMUX_PREFIX_CLASSICAL="${TERMUX_BASE_DIR}/usr"
TERMUX_PREFIX="${TERMUX_PREFIX_CLASSICAL}"
TERMUX_ETC_PREFIX_DIR_PATH="${TERMUX_PREFIX}/etc"
TERMUX_PROFILE_D_PREFIX_DIR_PATH="${TERMUX_ETC_PREFIX_DIR_PATH}/profile.d"
TERMUX_CONFIG_PREFIX_DIR_PATH="${TERMUX_ETC_PREFIX_DIR_PATH}/termux"
TERMUX_BOOTSTRAP_CONFIG_DIR_PATH="${TERMUX_CONFIG_PREFIX_DIR_PATH}/bootstrap"

# Path to CGCT tools
CGCT_DEFAULT_PREFIX="/data/data/${TERMUX_APP_PACKAGE}/files/usr/glibc"
export CGCT_DIR="/data/data/${TERMUX_APP_PACKAGE}/cgct"

export TERMUX_PACKAGES_DIRECTORIES=$(jq --raw-output 'del(.pkg_format) | keys | .[]' ${TERMUX_SCRIPTDIR}/repo.json)

# Allow to override setup.
for f in "${HOME}/.config/termux/termuxrc.sh" "${HOME}/.termux/termuxrc.sh" "${HOME}/.termuxrc"; do
	if [ -f "$f" ]; then
		echo "Using builder configuration from '$f'..."
		. "$f"
		break
	fi
done
unset f
