#!/bin/bash
##########################################################################
ABOUT="Repeat a command in a directory."
# ----------------------------------------------
# 2014-08-05 Dan Kopparhed
##########################################################################
THISFILE=$0
DIR=$1
CMD=$2
ITER=$3
args=("$@")
##########################################################################
f_usage()
{
	cat <<TXT
 $ABOUT
 Usage: ${THISFILE} <dir> <command> <iterations>
 example: $0 $PWD 10
TXT
}
##########################################################################

if [ -z "$1" ] & [ -z "$2" ] & [ -z "$3" ]; then
	f_usage
	exit
fi

# enable users aliases (presumably located in HOME/.bashrc):
shopt -s expand_aliases
source ~/.bashrc

COUNT=0
cd $DIR

for i in $(eval echo "{1..$ITER}")
do
	let COUNT=COUNT+1
	echo Running iteration $i/$ITER in dir $PWD
	# For echoing each line of output from command, e.g. "ls -la":
	IFS=$'\n'
	for x in $(eval $CMD)
	do
		echo $x
	done
done
echo Done!
