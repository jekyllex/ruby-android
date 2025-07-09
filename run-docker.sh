#!/bin/sh
# Adapted from: https://github.com/termux/termux-packages/blob/acf1df1e90034ce0100ac54726ae56792bf56859/scripts/run-docker.sh

set -e -u

TERMUX_SCRIPTDIR=$(cd "$(realpath "$(dirname "$0")")"; cd ..; pwd)

CONTAINER_HOME_DIR="/home/runner"
UNAME=$(uname)
if [ "$UNAME" = Darwin ]; then
	# Workaround for mac readlink not supporting -f.
	REPOROOT=$PWD
	SEC_OPT=""
else
	REPOROOT="$HOME"
	SEC_OPT=" --security-opt seccomp=$REPOROOT/scripts/profile.json"
fi

# Required for Linux with SELinux and btrfs to avoid permission issues, eg: Fedora
# To reset, use "restorecon -Fr ."
# To check, use "ls -Z ."
if [ -n "$(command -v getenforce)" ] && [ "$(getenforce)" = Enforcing ]; then
	VOLUME=$REPOROOT:$CONTAINER_HOME_DIR:z
else
	VOLUME=$REPOROOT:$CONTAINER_HOME_DIR
fi

: ${TERMUX_BUILDER_IMAGE_NAME:=ghcr.io/termux/package-builder@sha256:0ee468bc414ddad510667e6ef6719b104e5a9b45df2161eb8eab5855ed47b650}
: ${CONTAINER_NAME:=termux-package-builder}

USER=builder

if [ -n "${TERMUX_DOCKER_USE_SUDO-}" ]; then
	SUDO="sudo"
else
	SUDO=""
fi

echo "Running container '$CONTAINER_NAME' from image '$TERMUX_BUILDER_IMAGE_NAME'..."

# Check whether attached to tty and adjust docker flags accordingly.
if [ -t 1 ]; then
	DOCKER_TTY=" --tty"
else
	DOCKER_TTY=""
fi

$SUDO docker start $CONTAINER_NAME >/dev/null 2>&1 || {
	echo "Creating new container..."
	$SUDO docker run \
		--detach \
		--init \
		--name $CONTAINER_NAME \
		--volume $VOLUME \
		$SEC_OPT \
		--tty \
		$TERMUX_BUILDER_IMAGE_NAME
	if [ "$UNAME" != Darwin ]; then
		if [ $(id -u) -ne 1001 -a $(id -u) -ne 0 ]; then
			echo "Changed builder uid/gid... (this may take a while)"
			$SUDO docker exec $DOCKER_TTY $CONTAINER_NAME sudo chown -R $(id -u) $CONTAINER_HOME_DIR
			$SUDO docker exec $DOCKER_TTY $CONTAINER_NAME sudo chown -R $(id -u) /data
			$SUDO docker exec $DOCKER_TTY $CONTAINER_NAME sudo usermod -u $(id -u) builder
			$SUDO docker exec $DOCKER_TTY $CONTAINER_NAME sudo groupmod -g $(id -g) builder
		fi
	fi
}

# Set traps to ensure that the process started with docker exec and all its children are killed. 
. "$TERMUX_SCRIPTDIR/scripts/utils/docker/docker.sh"; docker__setup_docker_exec_traps

if [ "$#" -eq "0" ]; then
	set -- bash
fi

$SUDO docker exec --env "DOCKER_EXEC_PID_FILE_PATH=$DOCKER_EXEC_PID_FILE_PATH" --interactive $DOCKER_TTY --workdir "$HOME" $CONTAINER_NAME "$@"
