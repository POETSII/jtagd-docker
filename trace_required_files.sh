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


# Runs Quartus jtag stack and list which Quartus files/shared libraries are loaded
# The list may differ depending on what JTAG deviecs you have plugged in.
# Requires $QUARTUS_ROOTDIR to be set
#
# syntax: trace_required_files.sh <output_file_for_list>

FILELIST=$1
QUARTUSDIR=$(basename $QUARTUS_ROOTDIR)

TRACEDIR=/tmp/jtag
mkdir -p $TRACEDIR
strace -f -s999 -o $TRACEDIR/stjtagd $QUARTUS_ROOTDIR/bin/jtagd --foreground --debug  > $TRACEDIR/jtagd.log &
JTAGD=$!
echo "JTAGD=$JTAGD"
strace -f -s999 -o $TRACEDIR/stjtagconfig $QUARTUS_ROOTDIR/bin/jtagconfig > $TRACEDIR/jtagconfig.log
kill %1

grep -a open $TRACEDIR/stjtagd  | grep -v ENOENT | grep -v resumed | grep $QUARTUS_ROOTDIR | perl -lne "print \$2 if /($QUARTUSDIR\/(.*)\")/i" > $TRACEDIR/filelist.txt
grep -a open $TRACEDIR/stjtagconfig  | grep -v ENOENT | grep -v resumed | grep $QUARTUS_ROOTDIR | perl -lne "print \$2 if /($QUARTUSDIR\/(.*)\")/i" >> $TRACEDIR/filelist.txt
grep -a execve $TRACEDIR/stjtagd | cut -d '"' -f 2  | grep $QUARTUS_ROOTDIR | perl -lne "print \$2 if /($QUARTUSDIR\/(.*))/i" >> $TRACEDIR/filelist.txt
grep -a execve $TRACEDIR/stjtagconfig | cut -d '"' -f 2 | grep $QUARTUS_ROOTDIR | perl -lne "print \$2 if /($QUARTUSDIR\/(.*))/i" >> $TRACEDIR/filelist.txt


cat $TRACEDIR/filelist.txt | sort | uniq | grep -v '/$' > $FILELIST
