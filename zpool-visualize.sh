#!/bin/bash

die(){
    echo
    echo $1
    exit 1
}

[ -z "$1" ] && die "Usage $1 <zfs pool name>"

which tmux > /dev/null || die "tmux missing"
which iosnoop-perf > /dev/null || die "iosnoop-perf missing"

echo -n "examining pool '$1'..."
disks=$(zdb -C $1)
[ $? -eq 0 ] || die "unable to get information about disks for pool $1"
disks=$(echo "$disks" | grep -A4 "type: 'disk'" | grep "path:" | awk '{ print $2 }' | xargs readlink -f | sed -e 's/[0-9]*$//g' | xargs)
[ -z "$disks" ] && die "unable to parse zdb output for  pool '$1'"
echo "done"

x=$(tput cols)
y=$(tput lines)

[ "$x" -lt 180 ] && die "set terminal size at least 180x50"
[ "$y" -lt 50 ] && die "set terminal size at least 180x50"


[ -e "/var/$1.fifo" ] || mkfifo "/var/$1.fifo"
#[ -e "/var/$1-visualize.fifo" ] || mkfifo "/var/$1-visualize.fifo"

echo "monitoring $disks"
tmux new-session \; set mouse on\; split-window -h -l 90\; split-window -v -l 20\;\
     select-pane -t 1 \; send-keys "iosnoop-perf -s 2>/dev/null | tee /var/$1.fifo | ./dsk-peek.sh -v $disks" C-m\;\
     select-pane -t 0 \; send-keys "cat /var/$1.fifo | ./dsk-visualize.sh $disks" C-m\;\
     select-pane -t 2 \; send-keys "echo use this panel to perform io tests on pool '$1'" C-m
