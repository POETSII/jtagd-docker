#!/bin/bash

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
