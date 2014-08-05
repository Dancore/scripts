#!/bin/bash
##########################################################################
ABOUT="Repeat a command in a directory."
# ----------------------------------------------
# 2014-08-05 Dan Kopparhed
##########################################################################
THISFILE=$0
ITER=$1
DIR=$2
# CMD=$3
args=("$@")
##########################################################################
f_usage()
{
	cat <<TXT
 $ABOUT
 Usage: ${THISFILE} <iterations> <dir> <command>
 example: $0 10 $PWD "ls -la"
TXT
}
##########################################################################

if [ -z "$1" ] & [ -z "$2" ] & [ -z "$3" ]; then
	f_usage
	exit
fi
for ((i=2; i < $#; i++)) {
	CMD=$CMD"${args[$i]} "
}
echo command is \"$CMD\"

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
