#!/bin/bash

# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright (c) 2022 A. Theodore Markettos
#
# This software was developed by the University of Cambridge Computer
# Laboratory as part of the CAPcelerate project, funded by EPSRC grant
# EP/V000381/1.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

JTAG_CONF=$HOME/.jtag.conf

export QUARTUS_ROOTDIR=/local/ecad/altera/21.3pro/quartus

echo "Making sure all boards have firmware programmed..."
$QUARTUS_ROOTDIR/jtagconfig
killall jtagd
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
