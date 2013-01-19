#!/bin/sh
SCRIPT=$0
echo "script: $SCRIPT"
SCRIPTPATH=$(dirname ${SCRIPT})

export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
export LC_ALL="C"
export LANG="en_US.UTF-8"
export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="/root/Library"
export TMPDIR="/root/Library/tmp"
export LD_LIBRARY_PATH="${SCRIPTPATH}"
# export PLEX_MEDIA_SERVER_HOME="${SCRIPTPATH}"
ulimit -s 3000
./Plex\ Media\ Server &
