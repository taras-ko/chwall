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
	cp --parents --verbose -t $topdir "$file" | tee -a $logfile
	rm "$file" 2>/dev/null
	beep
}

trap "add2top" SIGRTMIN

# Skep to next
skip2next()
{
	_delay=0
}
trap 'skip2next' SIGUSR1

# Here we delete ugly image
# and switch to next
mv2trash()
{
	cp --parents --verbose -t $trashdir "$file" | tee -a $logfile
	rm "$file" 2>/dev/null
	beep
	_delay=0
}
trap 'mv2trash' SIGUSR2

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

pushd $targetdir

restdir=rest
topdir=top
trashdir=trash

for dir in $restdir $topdir $trashdir
do
	test -d $dir || mkdir -p $dir
done

export list=wallpapers.list

if [[ ! -s $list ]]; then
	find \( \
		-path "$topdir*" -o \
		-path "$trashdir*" -o \
		-path "$restdir*" \) -prune -type f -o \
		-type f \( -iname '*.jpg' -o -iname '*.png' \) >$list
fi

lnum=`wc -l $list | awk '{ print $1 }'`

while [ $lnum -gt 0 ]; do
	line=$((RANDOM % lnum + 1)) # Random generation from range [1..lnum]
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
	cp --parents --verbose -t $restdir "$file" | tee -a $logfile
	rm "$file" 2>/dev/null
	beep
done

popd

#trap - SIGINT
trap - USR1
trap - USR2

