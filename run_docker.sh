docker -D run --privileged -v /sys/bus/usb:/sys/bus/usb -v /dev/bus/usb:/dev/bus/usb -v /run/udev/control:/run/udev/control --net=host -p 1309:1309 jtagd
