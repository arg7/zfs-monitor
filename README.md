# zfs-monitor

Tools to visually asses disk activity in almost real time.

## dependencies

**tmux** and **iosnoop-perf** tools must be installed on the system.
console size must be greater than 180x50.

## zpool-visualize.sh

example: **zpool-visualize.sh rpool**

zpool-visualize.sh takes zpool name as argument and creates set of termux panels like this:

![complex pool io activity](/doc/compex-pool.png)

Left panel shows all pool vdev disks as a map. Yellow block rapresents disk reads and purple - disk writes.

Upper-right panel shows list of data blocks read or written.
Lower-right panel is a bash, you can use it to spawn disk io activity.

## dsk-peek.sh

example: **iosnoop-perf -s | ./dsk-peek.sh -v /dev/sda /dev/sdb**
  
dsk-peek.sh utility takes iosnoop-perf output as an input and list of disks as argument.
In output it adds dump of data readed/written, maximum size 256 bytes. If longer, it shows first and last 128 bytes. 
Use "-vv" to dump all data.

## dsk-visualize.sh

example: **iosnoop-perf -s | ./dsk-visualize.sh /dev/sda /dev/sdb**

shows realtime disk activity for selected disks.

more advanced usage can be: **iosnoop-perf -s | tee disk-io.log | ./dsk-visualize.sh /dev/sda /dev/sdb**
disk io activity will be logged to **disk-io.log** file and can be replayed later with **cat disk-io.log | ./dsk-visualize.sh /dev/sda /dev/sdb**
you can specify speedup factor with **"--replay 10"** command line switch, it will speedup 10 times the output.
if no **"--replay"** command switch is specified, utility will process input file at maximum speed.


Best regards,
AR
