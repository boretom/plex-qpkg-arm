Build Plex Media Server QPKG for QNAP arm-x19 NAS
=================================================

Prerequisites
-------------
* A QNAP arm-x19/arm-x12/arm-x10 series NAS and their variations (P/P II/P+/Pro).  
  x19 : TS-119, TS-219, TS-419  
  x12 : TS-112, TS-412  
  x10 : TS-110, TS-410
* Optware package has to be installed. In particular the `find` utility has to be installed. It is used to find empty directories, something the stock `find` can't do. Optware is available from the QNAP QPKG Center on your NAS.
* QDK, QNAP Development Kit can be found on the QNAP [wiki](http://wiki.qnap.com/wiki/QPKG_Development_Guidelines)

Assemble
--------
1. run `./assemble.sh` passing a Synology ARM package, e.g
````
./assemble /share/Public/PlexMediaServer-0.9.7.11.386-d353989-arm.spk
````
2. run `qbuild --exclude '.gitignore'
3. the QPKG file can be found in the `build` subdirectory and is named like PlexMediaServer_x.x.x.x.xxx_arm-x19.qpkg
