#!/bin/bash
##########################################################################
ABOUT="Repeat a command in a directory."
# ----------------------------------------------
# 2014-08-05 Dan Kopparhed
##########################################################################
THISFILE=$0
ITERATIONS=$1
DIR=$2
# CMD=$3
args=("$@")
##########################################################################
f_usage()
{
	cat <<TXT
 $ABOUT
 Usage: ${THISFILE} {iterations} {dir} {command}
 example: $0 10 $PWD ls -la
 Tip: use \\\$ITER for the current iteration or \\\$COUNT starting from zero
 example: $0 11 $PWD touch file\\\$COUNT.log
TXT
}
##########################################################################

if [ -z "$1" ] & [ -z "$2" ] & [ -z "$3" ]; then
	f_usage
	exit
fi

for ((a=2; a < $#; a++)) {
	CMD=$CMD${args[$a]}" "
}
echo command is \"$CMD\"

# enable users aliases (presumably located in HOME/.bashrc):
shopt -s expand_aliases
source ~/.bashrc

COUNT=0
cd $DIR

for ITER in $(eval echo "{1..$ITERATIONS}")
do
	echo Running iteration $ITER/$ITERATIONS in dir $PWD
	# For nice echoing of each line of output from command, e.g. from "ls -la":
	IFS=$'\n'
	for output in $(eval $CMD)
	do
		echo $output
	done
	let COUNT=COUNT+1
done
echo Done!
