#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="PlexMediaServer"
PUBLIC_SHARE=`/sbin/getcfg SHARE_DEF defPublic -d Public -f /etc/config/def_share.info`

# Determine BASE installation location according to smb.conf
BASE=
publicdir=`/sbin/getcfg $PUBLIC_SHARE path -f /etc/config/smb.conf`
if [ ! -z $publicdir ] && [ -d $publicdir ];then
	publicdirp1=`/bin/echo $publicdir | /bin/cut -d "/" -f 2`
	publicdirp2=`/bin/echo $publicdir | /bin/cut -d "/" -f 3`
	publicdirp3=`/bin/echo $publicdir | /bin/cut -d "/" -f 4`
	if [ ! -z $publicdirp1 ] && [ ! -z $publicdirp2 ] && [ ! -z $publicdirp3 ]; then
		[ -d "/${publicdirp1}/${publicdirp2}/${PUBLIC_SHARE}" ] && BASE="/${publicdirp1}/${publicdirp2}"
	fi
fi

# Determine BASE installation location by checking where the Public folder is.
if [ -z $BASE ]; then
	for datadirtest in /share/HDA_DATA /share/HDB_DATA /share/HDC_DATA /share/HDD_DATA /share/MD0_DATA; do
		[ -d $datadirtest/$PUBLIC_SHARE ] && BASE="/${publicdirp1}/${publicdirp2}"
	done
fi
if [ -z $BASE ] ; then
	echo "The Public share not found."
	/sbin/write_log "[Plex Media Server] The Public share not found." 1
	exit 1
fi
		
	QPKG_DIR=${BASE}/.qpkg/$QPKG_NAME

case "$1" in
  start)
    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME is disabled."
        exit 1
    fi
	
	if [ -f ${QPKG_DIR}/lock ]; then
		echo "Plex Media Server is currently running or hasn't been shutdown properly. Please stop it before starting a new instance."
		exit 0
	fi
	
	# create the lock file
	touch ${QPKG_DIR}/lock
	
    echo "Creating Library link ..."
	[ -d /root/Library ] || /bin/ln -sf ${QPKG_DIR}/Library /root/Library
	[ -d /root/.plex ] || /bin/ln -sf ${QPKG_DIR} /root/.plex

	export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
	# export LC_ALL="en_US.UTF-8"
	export LC_ALL="C"
	export LANG="en_US.UTF-8"
	export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="/root/Library"
	export TMPDIR="/root/Library/tmp"
	export LD_LIBRARY_PATH=${QPKG_DIR}
	ulimit -s 3000
	cd ${QPKG_DIR}
	echo "Starting Plex Media Server ..."
	./Plex\ Media\ Server &
		
    ;;

  stop)

	if [ ! -f ${QPKG_DIR}/lock ]; then
		echo "Plex Media Server hasn't been enabled or started ..."
		exit 0
	fi
	# PLEX_PID=`${QPKG_DIR}/bin/pgrep Plex\ Media`
        PLEX_PID="$(cat "${QPKG_DIR}/Library/Plex Media Server/plexmediaserver.pid")"
	if [ -z "$PLEX_PID" ]; then
		echo "Plex Media Server might not be running."
	else 
		echo "Stopping Plex Media Server ..."
		kill $PLEX_PID
	fi
	
	/bin/rm -f ${QPKG_DIR}/lock

	echo "Removing Library link ..."
	/bin/rm -rf /root/Library
	/bin/rm -rf /root/.plex

    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
