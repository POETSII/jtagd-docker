#!/bin/bash

FILELIST=filelist_quartus22.1pro.txt

rm -rf staging
mkdir -p staging

for FILE in $(cat $FILELIST) ; do
	mkdir -p staging/$(dirname $FILE)
	cp -a $QUARTUS_ROOTDIR/$FILE staging/$FILE
done

docker build -t jtagd .

