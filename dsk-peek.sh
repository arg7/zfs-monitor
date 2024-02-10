#!/bin/bash

v=""
[[ "$1" = "-v" ]]  && v="v"  && shift
[[ "$1" = "-vv" ]] && v="vv" && shift

declare -a dn
declare -a dd
declare -a ss
declare -a ddi

i=0

for val in "$@"
do

    dn[$i]=$val
    b=$(basename "$val")
    dv=$(lsblk | grep "^$b" | awk '{print $2}')
    dv=${dv//:/,}
    dd[$i]="$dv"
    ss[$i]=$(cat /sys/block/$b/queue/hw_sector_size)
    dn[$i]=$b
    ddi[$dv]=$i

    (( i++ ))
done

find_dd() {
    i=0
    for a in "${dd[@]}"
    do
	[ "$1" = "$a" ] && echo $i && break
	((i++))
    done
}

#echo "${dn[@]}"
read;read
while read -r tm app pid op dsk blk sz l
do
    i=${ddi[$dsk]}
    [[ -z "$i" ]] && continue
    [[ "$app" = "dd" ]] && continue

    ((skp = $blk*$ss))


    echo "$tm" "$app" "$pid" ${dn[$i]} $op $blk $sz $l

    [ -z "$v" ] && continue

    dd if=/dev/${dn[$i]} bs=1 skip=$skp count=$sz 2>/dev/null > /tmp/dump.bin
    if [ "$sz" -gt 256 ] && [ ! "$v" = "vv" ]; then
        head -c 128 /tmp/dump.bin | hexdump -C
        (( a = $sz-256 ))
        echo --- skiped $a bytes ---
        tail -c 128 /tmp/dump.bin | hexdump -C
    else
        hexdump -C /tmp/dump.bin
    fi | while read line
    do
        echo "          $line"
    done
    echo 
done
