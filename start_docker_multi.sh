#!/bin/bash

# cleanup via:
#  docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)

JTAG_CONF=$HOME/.jtag.conf

export QUARTUS_ROOTDIR=/local/ecad/altera/21.3pro/quartus

echo "Making sure all boards have firmware programmed..."
#$QUARTUS_ROOTDIR/jtagconfig
#killall jtagd

# now boards are 09fb:6010 not unprogrammed 09fb:6810, so we
# don't need to worry about udev

echo "" > $JTAG_CONF

BOARD=0
for DEV in /sys/bus/usb/devices/* ; do
  if [ "$(cat $DEV/idVendor 2>/dev/null)" == "09fb" ] && [ "$(cat $DEV/idProduct 2>/dev/null)" == "6010" ] ; then
    BOARD=$(expr $BOARD + 1)
    PORT=$(expr $BOARD + 1309)
    echo "Found a device at $DEV, naming board $BOARD"
    docker run -d --privileged --name "jtagd$BOARD"	\
	-p 127.0.0.1:$PORT:1309 					\
	-v /var/tmp:/sys/bus/usb			\
        -v $DEV:$DEV					\
        -v /dev/bus/usb:/dev/bus/usb			\
        jtagd
    cat >> $JTAG_CONF <<-EOF
	Remote$BOARD {
	        Host = "localhost:$PORT";
	        Password = "password";
	}
EOF
  fi
done

echo "Starting dummy jtagd with no boards on port 1309"
docker run -d --privileged --name "jtagdDUMMY"	\
  -p 127.0.0.1:1309:1309 					\
  -v /var/tmp:/sys/bus/usb			\
  -v /dev/bus/usb:/dev/bus/usb			\
  jtagd
