#!/usr/bin/env bash
# Point termux-packages properties at the JekyllEx app id so prefixes land under
# /data/data/xyz.jekyllex/... Upstream properties stay otherwise untouched
# (NDK r29, build-tools, path layout). Run after checkout, before builds.
set -euo pipefail

PROPERTIES_FILE="${1:-scripts/properties.sh}"

if [ ! -f "$PROPERTIES_FILE" ]; then
	echo "[!] properties file not found: $PROPERTIES_FILE" 1>&2
	exit 1
fi

if grep -q 'TERMUX_APP__PACKAGE_NAME="xyz.jekyllex"' "$PROPERTIES_FILE"; then
	echo "[*] JekyllEx identity already applied in $PROPERTIES_FILE"
	exit 0
fi

tmp="$(mktemp)"
sed \
	-e 's/^TERMUX_APP__PACKAGE_NAME="com.termux"/TERMUX_APP__PACKAGE_NAME="xyz.jekyllex"/' \
	-e 's|^export CGCT_DIR="/data/data/com.termux/cgct"|export CGCT_DIR="/data/data/xyz.jekyllex/cgct"|' \
	"$PROPERTIES_FILE" > "$tmp"
mv "$tmp" "$PROPERTIES_FILE"

if ! grep -q 'TERMUX_APP__PACKAGE_NAME="xyz.jekyllex"' "$PROPERTIES_FILE"; then
	echo "[!] Failed to set TERMUX_APP__PACKAGE_NAME in $PROPERTIES_FILE" 1>&2
	exit 1
fi

echo "[*] Applied JekyllEx identity (xyz.jekyllex) to $PROPERTIES_FILE"
