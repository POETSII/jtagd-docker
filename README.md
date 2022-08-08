Parallelising Altera/Intel FPGA 'jtagd' in Docker
=================================================

Altera/Intel's 'jtagd', a key component when programming Intel FPGAs via JTAG, has 
concurrency issues. They are particularly bad if you have multiple boards attached and are 
doing heavyweight communication with them all at the same time, eg parallel programming or 
bulk data transfer.  jtagd only single threads and does not properly load balance its 
competing demands which causes JTAG disconnections and timeouts.  It is also fairly CPU and 
memory hungry for the simple task that it does.

This repository contains a series of scripts that run jtagd in a Docker container, and 
launches a separate Docker container for every USB programmer attached to your machine.  
Docker is used so we can isolate the jtagds from each other, and each jtagd thinks it's 
talking to exactly one programmer so it doesn't have to multiplex multiple clients.  This 
allows parallelisation across multiple cores.

Due to the way the Altera/Intel JTAG stack works, clients will look for an existing JTAG 
daemon listening on port 1309 and start their own jtagd if they don't find it.  For this 
reason we start a dummy jtagd, which has no USB programmers visible, on port 1309, and then N 
programmers listening on ports 1310 and upwards which talk to each USB device.  A config file 
in $HOME/.jtag.conf is emitted to configure Quartus to use this programming setup.

Preparation
-----------

This step is optional: a pre-prepared filelist can be found in filelist_quartus_22.1pro.txt

First, you need to generate a folder of files from your Quartus install that corresponds to 
the minimal libraries to run the jtag stack.  On the machine where the boards are connected, 
first set QUARTUS_ROOTDIR to the location of your Quartus install and run the tracing 
script:

```
export QUARTUS_ROOTDIR=/opt/intelFPGA/21.3pro/quartus
sudo apt install strace
./trace_required_files.sh filelist_quartus_21.3pro.txt
```

This runs jtagd and jtagconfig using strace and outputs a list of libraries and other files 
that they accessed, scraped from the strace output.


Setup
-----

Once the filelist is available, build the Docker container:

```
export QUARTUS_ROOTDIR=/opt/intelFPGA/21.3pro/quartus
./build_docker.sh
```

(you may need to edit the script if not using the supplied filelist_quartus_22.1pro.txt)

The container is built with the name 'jtagd':

```
$ docker images
REPOSITORY   TAG       IMAGE ID       CREATED             SIZE
jtagd        latest    74c2fae7e8ab   About an hour ago   184MB
```

Run
---

To launch the fleet of jtagd containers:

```
$ ./start_docker_multi.sh
Making sure all boards have firmware programmed...
Found a device at /sys/bus/usb/devices/5-2.3.1, naming board 1
0f855f22901296946e41ebd932f84a881ed4501df26b948f72ea91d28d3ef5e9
Found a device at /sys/bus/usb/devices/5-2.3.2, naming board 2
7bf685f7d6ca50c8f79de176bf6ab20dd405995a7d8b7795165d5f0a8fd4f461
Found a device at /sys/bus/usb/devices/5-2.3.3, naming board 3
c5c134223607e9177c31468967302856932034b630c9adb1a8a1d04aee03ccf1
Found a device at /sys/bus/usb/devices/5-2.3.4, naming board 4
767761dd8a56bfc98005a054add7430d89621fc3753a514ec2f6df76d6caa1ba
Found a device at /sys/bus/usb/devices/5-2.4.1, naming board 5
db227839bc2eae323deb553d1e135995eeb0eaff8022bb0a97d740f3df8518cf
Found a device at /sys/bus/usb/devices/5-2.4.2, naming board 6
02b56c9f7c81e2a9c8b42dc0b464bbdb2cb5f06847c9b26c234abcd5b109c1ff
Found a device at /sys/bus/usb/devices/5-2.4.3, naming board 7
24808ce550901b25e42213deede0c2d1d4e7e1d0edb035f1c7c7d5dc79b19d6f
Found a device at /sys/bus/usb/devices/5-2.4.4, naming board 8
995ea45e4b24e3fbff6a451a257bc57f210b3f3d172521d0c0006b325e6194a5
Starting dummy jtagd with no boards on port 1309
b7f0e47b2fb1fe5224b22051e1437383baa49450b7a5b5b542ea4888f54c81d7

```

and to stop them:

```
$ ./stop_docker.sh
```

Limitations
-----------

Currently the script is only enabled for USB devices vendor:product 09fb:6010, although other 
devices (eg USB Blaster I) can trivially be enabled.

The script will not handle hotplug events.  See below for more details.

Technicalities
--------------

There are at least two versions of the USB-Blaster hardware in use:

The original USB-Blaster used an FT245R chip to essentially bitbang the four JTAG control 
lines - two USB transactions per clock cycle.  This puts a heavy load on the JTAG and USB 
stacks, which is likely a reason for the concurrency problems.

The FT245R is USB 1.1 Full Speed only, and additionally poor hub configuration can cause 
bandwidth problems.  Many cheaper USB 2.0 hubs are only USB 1.1 SST, which means all USB FS 
communications is routed through a single 12Mbps link.  This causes bandwidth starvation of 
the timing-critical JTAG traffic.  Better hubs, and it seems most USB 3.0 hubs, are MST, 
which means the USB 1.1 FS traffic can be up-converted to run over a 480Mbps USB 2.0 High 
Speed link.

USB-Blaster clones work in the same way, typically using a microcontroller or CPLD instead of 
the FT245 chip.  We have no experience with these.

USB-Blaster II devices use a Cypress CY7C68013A (commonly called 'FX2') microcontroller 
instead of the FT245.  This supports USB 2.0 High Speed, so is faster and more reliable. 
(some of the Blaster clones also use this chip).  The typical mode of operation of the 
Blaster II is as follows.  The chip powers up in an unprogrammed state, with the 
vendor:product id 09fb:6810.  jtagd then downloads a firmware image 
($QUARTUS_ROOTDIR/linux64/blaster_6810.hex) to it, and the chip resets and comes back with a 
new id of 09fb:6010.  This causes a new hotplug event as if a new device was plugged in.

On Linux, passing through and filtering udev events to Docker containers is awkward, so this 
script has a workaround.  First, it runs jtagd outside of Docker, which causes all of the FX2 
microcontrollers to receive their firmware and hotplug themselves back in as 09fb:6010.  
Then, when we start the Docker containers, they bind to that ID and have no need for hotplug 
events.
