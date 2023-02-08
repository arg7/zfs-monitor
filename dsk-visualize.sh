#!/bin/bash

find_dsk() {
    for (( n=0; n < ${#disks[*]}; n++))
    do
	[ "/dev/$1" = "${disks[$n]}" ] && printf "%s" $n && break
    done
}

finalize() {
    tput op
    tput cnorm
    tput cup $(($lines-1)) 0
    exit $1
}

stats() {
    ct=$(awk '{print $1}' /proc/uptime)
    cd=$(echo "$tm $ct" | awk '{print $2-$1}')
    for (( n=0; n < ${#disks[*]}; n++))
    do
	xz0=$(printf "\033[%d;%dH" "${scr_y[$n]}" "0")
	r=$(numfmt --to=iec-i ${rsize[$n]})
	w=$(numfmt --to=iec-i ${wsize[$n]})
	ds=$(numfmt --to=iec-i ${dsb[$n]})
	ra=""
	wa=""
	[[ ${rcnt[$n]} -gt 0 ]] && ((ra=${rsize[$n]}/${rcnt[$n]}))
	[[ -z "$ra" ]] || ra=$(numfmt --to=iec-i $ra)
	[[ ${wcnt[$n]} -gt 0 ]] && ((wa=${wsize[$n]}/${wcnt[$n]}))
	[[ -z "$wa" ]] || wa=$(numfmt --to=iec-i $wa)
	m="${disks[$n]} ($ds): TIME: $tm($cd); RBLK: ${rcnt[$n]}; RDATA: $r; RAVG: $ra; WBLK: ${wcnt[$n]}; WDATA: $w; WAVG: $wa    "
	echo -en "$xz0$cfb$cbw$m$el"
    done
}

log1=""

log() {
    local t
    t=$(date +%s%3N)
    ((t=$t-$d0))
    printf "%08d: %s\n" "$t" "$1" >> "$dbgf"
}

log_null() { 
    return 
}

replay=""
replay_factor="1"
dbgf=""
logf="log_null"

if [ "$1" = "--replay" ]; then
    replay="1"
    shift
    if [[ "$1"  =~ ^[0-9]+ ]]; then
	replay_factor="$1"
	shift
    fi
fi

if [ "$1" = "--debug" ]; then
    logf="log"
    shift
    dbgf="$1"
    echo -n > "$1"
    shift
fi

disks=( "$@" )

#exit 1

declare -a dsb
declare -a dsz
declare -a rcnt
declare -a rsize
declare -a wcnt
declare -a wsize
declare -a dskn
declare -a ddi

lines=$(tput lines)
cols=$(tput cols)
((lines--))

tput cup $lines 0
tput setb 7
tput setf 5
echo -en ""

s=0
for (( n=0; n < ${#disks[*]}; n++))
do
    dsb[$n]=$(blockdev --getsize64 ${disks[$n]})
    dsz[$n]=$(blockdev --getsz ${disks[$n]})
    ((dss[$n]=${dsb[$n]}/${dsz[$n]}))
    dskn[$(basename "${disks[$n]}")]=$n

    b=$(basename "${disks[$n]}")
    dv=$(lsblk | grep "^$b" | awk '{print $2}')
    dv=${dv//:/,}
    ddi["$dv"]=$n

    rcnt[$n]=0
    rsize[$n]=0
    wcnt[$n]=0
    wsize[$n]=0

    ((s=$s+${dsz[$n]}))
done

declare -A matrix

declare -a scr_y
declare -a scr_d
declare -a scr_blk
i=0
for ((n=0; n < ${#disks[*]}; n++))
do
    scr_y[$n]=$i
    ((d=$lines*${dsz[$n]}/$s))
    [[ $d -lt 1 ]] && d=1
    ((scr_blk[$n]=${dsz[$n]}/($d*$cols)))
    ((d++))
    scr_d[$n]=$d
    ((i=$i+$d))
done



op=$(tput op)
cfb=$(tput setaf 0)
cbw=$(tput setab 7)
cbb=$(tput setab 0)
cfg=$(tput setab 2)
cbm=$(tput setab 6)
cbg=$(tput setab 2)
cby=$(tput setab 3)
cbp=$(tput setab 5)
el=$(tput el)

tput civis
echo -en "$cbb$cfw"
tput clear

tput cup $lines 0
tput setab 7
tput setaf 4
echo -en "RBLK - "
echo -en "$cby"
echo -en "sectors read"
echo -en "$cbw"
echo -en "; WBLK - "
echo -en "$cbp"
echo -en "sectors writen"
echo -en "$cbw"
echo -en "; RAVG - average block size during read; WAVG - average block size diring write $el"

# Set a trap for SIGINT and SIGTERM signals
trap finalize SIGTERM SIGINT

d0=""
d=0
tm=0
cf=cfw
cb=cbb

hits=0
cnt=0


#$logf "start"

while true 
do

    [ $(($cnt%100)) -eq 0 ] && stats

    read -t 1 -r tt app pid op dsk blk sz lat
    r=$?
    [ $r -gt 128 ] && continue
    [ $r -eq 0 ] || break

#    $logf "read: tm=$tm app=$app pid=$pid dsk=$dsk op=$op blk=$blk sz=$sz lat=$lat"

    [[ "$tt" =~ ^([0-9]+[.])?[0-9]+$ ]] || continue
    [[ -z "$lat" ]] && continue 

    ((cnt++))

    tm=$(printf "%.3f" "$tt")

    if [[ "$replay" = "1" ]]; then
	tms=${tm//./}
	[[ -z "d0" ]] && d0=$tm
	while true
	do
#	    $logf "replay"
	    d11=$(date +%s%3N)
	    d22=$(($tms/$replay_factor+$d0-$d11))
	    [[ "${d22:0:1}" = "-" ]] && break
	    sleep 0.1
        done
    fi
    
    i=${ddi["$dsk"]}
    [[ -z "$i" ]] && continue

    h=${scr_d[$i]}
    ((h=$h-2))
    ((scrbs=${dss[$i]}*${scr_blk[$i]}))
    ((lc=$h*$cols))

#   $logf "find_dsk: $i"
    while [ "$sz" -gt 0 ]
    do
	(( t = $blk*$lc/${dsz[$i]} ))
	(( l = $t/$cols ))
	(( c = $t%$cols + 1 ))
	(( l = $l + ${scr_y[$i]} + 2 ))

	bsz=$sz
	[[ $bsz -gt $scrbs ]] && bsz=$scrbs 

	o=${op:0:1}
	if [ "$o" = "R" ]; then
	    ((rcnt[$i]=${rcnt[$i]}+1))
	    ((rsize[$i]=${rsize[$i]}+$bsz))
	    cb="$cby"
	fi
	if [ "$o" = "W" ]; then
	    ((wcnt[$i]=${wcnt[$i]}+1))
	    ((wsize[$i]=${wsize[$i]}+$bsz))
	    cb="$cbp"
	fi

	s=${matrix[$l,$c]}
	if [ ! "$s" = "$o" ]; then
#	    $logf "show: $o at $l:$c"
	    printf "\033[%d;%dH%s " "$l" "$c" "$cb"
	    matrix[$l,$c]=$o
#	else
#	    ((hits++))
	fi

	(( sz = $sz - $scrbs ))
	(( blk = $blk + ${scr_blk[$i]} ))
#	[[ "$sz" -gt 0 ]] && $logf "repeat"
    done

done

finalize 0