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

transfer_image()
{
	local src="$1"
	local src_dir="`dirname \"$src\"`"
	local dest="$2"
	local dest_dir="$dest/$src_dir"

	if [[ $transfer_flag == "hard" ]]; then
		cp --parents --verbose -t $dest "$src" | tee -a $logfile
		rm "$file" 2>/dev/null
	else # "soft" transfer
		local abs_src="`readlink -f \"$src\"`"

		if [[ ! -e "$dest_dir" ]]; then
			mkdir -p "$dest_dir"
		fi

		ln -sv "$abs_src" "$dest_dir" | tee -a $logfile
	fi

	beep
}

# Add to favourite
add2top()
{
	transfer_image "$file" $topdir
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
	transfer_image "$file" $trashdir
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

pushd "$targetdir"

restdir=$targetdir/rest
topdir=$targetdir/top
trashdir=$targetdir/trash

for dir in $restdir $topdir $trashdir
do
	test -d $dir || mkdir -p $dir
done

export list=wallpapers.list

if [[ ! -s $list ]]; then
	find \( \
		-path "*$topdir*" -o \
		-path "*$trashdir*" -o \
		-path "*$restdir*" \) -prune -type f -o \
		-type f \( -iname '*.jpg' -o -iname '*.png' \) >$list
fi

lnum=`wc -l $list | awk '{ print $1 }'`

while [ $lnum -gt 0 ]; do
	line=$((RANDOM % lnum + 1)) # Random generation from range [1..lnum]
	# Skip to next image
	file=`sed -n "${line}p" $list`
	log -n "${lnum}. "
	feh --scale-down -Z -d --bg-max "$file"
	sed -i "${line}d" $list
	((lnum--))
	for ((i=1; i<=_delay; i++)); do
		sleep 1
	done
	_delay=$default_delay
	transfer_image "$file" $restdir
done

popd

#trap - SIGINT
trap - USR1
trap - USR2

