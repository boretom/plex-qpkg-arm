#!/bin/bash

CHOWN=/bin/chown
CP=/bin/cp
FIND=/opt/bin/find
MKDIR=/bin/mkdir
MV=/bin/mv
RM=/bin/rm
SED=/bin/sed
TAR=/bin/tar

TMP_DIR="$(dirname $0)/tmp"

function usage () {
   echo "usage: $(basename $0) <Synology ARM PMS package (*.spk)"
}

# check number of arguments
if [[ ! $# -eq 1 ]]; then
   echo "[ERROR] incorrect number of arguments. One (1) argument expected but $# arguments passed"
   echo
   usage
   exit 1
fi

# check if Optware 'find' is installed. Needed since stock find doesn't support searching
# for empty directories
if [[ ! -e $FIND ]]; then
   echo "[ERROR] Optware 'find' missing. Not found in $(dirname $FIND)!"
   exit 2
fi

syno_arm_package="$1"
# check if Synology package exists
if [[ ! -f  ${syno_arm_package} ]]; then
   echo "[ERROR] Synology ARM package ${syno_arm_package} doesn't exist"
   exit 3
fi

# check Plex version
plex_version="$(echo "$syno_arm_package" | cut -d'-' -f2)"
qpkg_plex_version="$(echo "$plex_version" | cut -b1-10)"
echo "[INFO] Plex version $plex_version dedected. Will be QPKG version $qpkg_plex_version..."

echo "[INFO] set version number and create qpkg.conf.new"
$SED -e "s/^QPKG_VER=\"[0-9.]*\"$/QPKG_VER=\"$qpkg_plex_version\"/g" \
    -e "s/^# version \([0-9]\.[0-9.]*\) \(.*\)$/# version ${plex_version} \2/g" qpkg.cfg > qpkg.cfg.v$plex_version

builddate="$(date +'%Y%m%d_%H%M%S')"
# extract Syno ARM package
SYNO_TMP_DIR="${TMP_DIR}/Plex.Syno-arm.$builddate"
echo "[INFO] extract Synology ARM package to $SYNO_TMP_DIR"
if [[ ! -d "$SYNO_TMP_DIR" ]]; then
   $MKDIR -p "$SYNO_TMP_DIR/package"
fi

TAR_OPTION=''
tar --test-label -zf $syno_arm_package > /dev/null 2>&1 && TAR_OPTION='-z '
if [[ "x$TAR_OPTION" = "x" ]]; then
   echo "[INFO] Synology SPK is a POSIX TAR archive..."
else
   echo "[INFO] Synology SPK is a gzip compressed archive..."
fi
$TAR $TAR_OPTION -xf $syno_arm_package -C $SYNO_TMP_DIR > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
   echo "[ERROR] extracting Synology package failed with error code $?"
   exit 4
fi
$TAR -xzf $SYNO_TMP_DIR/package.tgz -C $SYNO_TMP_DIR/package/ > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
   echo "[ERROR] extracting Synology package failed with error code $?"
   exit 5
fi

echo "[INFO] move Syno package files from \"$SYNO_TMP_DIR/package\" to \"arm-x19\""
$MV $SYNO_TMP_DIR/package/* arm-x19/

echo "[INFO] search for empty directories and create a .gitignore files in them..."
$FIND ./arm-x19 -type d -empty -exec touch {}/.gitignore \;

echo "[INFO] delete Synology specific files in arm-x19..."
$RM -rf arm-x19/dsm_config

echo "[INFO] set user/group to admin:adminstrators for all files in arm-x19"
$CHOWN -hR admin:administrators arm-x19/

echo "[INFO] use new qpkg.conf"
$MV qpkg.cfg qpkg.cfg.old
$MV qpkg.cfg.v$plex_version qpkg.cfg

echo "[INFO] now run qbuild --exclude \".gitignore\" to create the package"

exit 0
