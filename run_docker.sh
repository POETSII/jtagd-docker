#!/bin/sh
#docker -D run -p $1:1309 jtagd
DEVICE=$1
QUARTUS_ROOTDIR=/local/ecad/altera/21.3pro/quartus ./build-docker.sh && \
docker -D run --privileged -v /var/tmp:/sys/bus/usb \
	-v /sys/bus/usb/devices/5-2.3.2/:/sys/bus/usb/devices/5-2.3.2 \
	-v /dev/bus/usb:/dev/bus/usb \
	jtagd
