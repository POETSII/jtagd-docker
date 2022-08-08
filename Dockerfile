FROM ubuntu:20.04

RUN \
	apt-get -y update	&&\
	apt-get -y install locales libncurses5 libtinfo5 libtinfo6 zlib1g \
		libudev1 libpcre3 udev usbutils	strace &&\
	locale-gen en_US.UTF-8	&&\
	update-locale
	

RUN \
	mkdir -p /usr/local/lib/quartus	&&\
	ln -s /lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libudev.so.0

COPY	./staging /usr/local/lib/quartus
COPY	./jtagd.conf /etc/jtagd/jtagd.conf
	
#CMD	["/usr/bin/strace", "-f", "-o", "/var/log/strace", "/usr/local/lib/quartus/bin/jtagd", "--foreground", "--debug"]
CMD	["/usr/local/lib/quartus/bin/jtagd", "--foreground", "--debug"]
