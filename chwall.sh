#!/bin/bash
#set -x

prog=`basename $0 .sh`

# Delay seconds to display image
default_delay=900
_delay=$default_delay

beep()
{
	echo -ne '\a'
}

# Add to favourite
add2top()
{
	f=`readlink -f "$file"`
	mv -v "$f" $topdir 2>/dev/null | tee -a $logfile && beep
}

trap "add2top" SIGRTMIN

# Skep to next
skip()
{
	_delay=0
}
trap 'skip' SIGUSR1

# Here we delete ugly image
# and switch to next
del_cur()
{
	rm -fv "$file" | tee -a $logfile && beep
	_delay=0
}
trap 'del_cur' SIGUSR2

cleanup()
{
	log "interruption detected"
	exit 0
}
trap 'cleanup' SIGINT

log()
{
	echo $@ | tee -a $logfile
}

log "My PID is $$"
echo $$ >/tmp/${prog}.pid

basedir=~/.wallpapers #default wallpapers directory
logfile=$basedir/chwall.log
touch $logfile

if [ -n "$1" ]; then
	targetdir=$1
	echo `readlink -f $targetdir` >$basedir/chwall-last-target
else
	targetfile=$basedir/chwall-last-target
	if [ -e $targetfile ]; then
		targetdir=$(cat $targetfile)
	else
		log "Error: \$1 is empty, specify target dir."
		exit 1
	fi
fi

targetdir=`readlink -f $targetdir` # Get absolute path for find util
restdir=${targetdir}/rest
topdir=${targetdir}/top

for dir in $restdir $topdir
do
	test -d $dir || mkdir -p $dir
done

export list=$targetdir/wallpapers.list

if [[ ! -e $list ]]; then
	find $targetdir -type f \( -iname '*.jpg' -o -iname '*.png' \) >$list
fi

lnum=`wc -l $list | awk '{ print $1 }'`

while [ $lnum -gt 0 ]; do
	line=$((RANDOM % lnum))
	# Skip to next image
	file=`sed -n "${line}p" $list`
	log -n "${lnum}. "
	feh -d --bg-max "$file"
	sed -i "${line}d" $list
	((lnum--))
	for ((i=1; i<=_delay; i++)); do
		sleep 1
	done
	_delay=$default_delay
	mv -v "$file" $restdir 2>/dev/null | tee -a $logfile && beep
done

#trap - SIGINT
trap - USR1
trap - USR2

