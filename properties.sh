#!/usr/bin/env bash
# Intentionally not a full properties.sh.
#
# Termux NDK r29 / path layout / validators live in upstream
# termux-packages scripts/properties.sh (pinned in CI).
# Apply JekyllEx package identity with:
#   ./apply-jekyllex-identity.sh path/to/scripts/properties.sh
#
# Do not copy this file over upstream properties.sh.
echo "Use apply-jekyllex-identity.sh against upstream scripts/properties.sh" 1>&2
exit 1
