#!/bin/bash
##########################################################################
ABOUT="Script for syncing many and large log files being updated in realtime."
# Assumes that the logfiles follow a certain format with date and time etc
# in the file name.
# ------------------------------------------------------------------------
# 2014-08-11 Dan Kopparhed
##########################################################################
THISFILE=${0##*/}
# args=("$@")
# COMMAND=$1
STARTTIME=$2
STOPTIME=$3
SYSTZ="CEST"
LOCALTZ=$(date +%Z)
LOGPATH="./logfiles"
CMD_CLEANDB="./cleanupdb.pl"
CMD_RSYNC="./rsync.pl"
CMD_CSV2DB="./csv2db.pl"
RUNONCE=0
# set to stop script if comamand fails:
set -e
##########################################################################
f_usage()
{
	cat <<TXT
 $ABOUT
 Usage: ${THISFILE} [COMMAND] [ARGS]
 	start 			Start the process, with optional args [STARTTIME] [STOPTIME]
 					ARGS formatted like date string, e.g: "2014-08-12 16:51:01"
 					No ARGS == "auto" date/time (normal behavior).
 	startonce		Start but stop after running once.
 	clean 			Delete old data and CSV files.
 	cleanstart		First clean, then start.
 	help			This text.
TXT
}
##########################################################################
f_clean()
{
	echo "Clean up log files"
	# $(rm $LOGPATH/*.csv)
	echo "Clean up DB"
	$CMD_CLEANDB
}
##########################################################################
case "$1" in
clean)
	f_clean
	exit
	;;
cleanstart)
	f_clean
	;;
cleanstartonce)
	f_clean
	RUNONCE=1
	;;
startonce)
	RUNONCE=1
	;;
start)
	;;
*)
	f_usage
	exit 2
	;;
esac

# Make sure the TZ is correct to avoid the TZ-bug
if [ $LOCALTZ != $SYSTZ ]; then
	SETTZ="TZ=$SYSTZ"
# else
# 	echo "Sys TZ == local TZ"
fi
# translate to epoch timestamp:
if [ ! -z "$STARTTIME" ]; then
	STARTTS=$($SETTZ date -d "$STARTTIME" +%s)
fi
if [ ! -z "$STOPTIME" ]; then
	STOPTS=$($SETTZ date -d "$STOPTIME" +%s)
fi

echo "Starting with pid: $$"
# disown
# Make sure we find the first minute immediately:
LASTMIN=-1

echo "Starting loop"
# enter eternal loop:
for (( ; ; ))
do
	NEWMIN=$($SETTZ date +%M)
	if [ $NEWMIN -ne $LASTMIN ]; then
		LASTMIN=$NEWMIN
		SEC=$($SETTZ date +%S)
		echo "NEW minute started (HH:$LASTMIN:$SEC)"
		echo "calling rsync"
		# $CMD_RSYNC
		echo "calling csv2db"
		$CMD_CSV2DB $STARTTS $STOPTS
	fi
	if [ $RUNONCE ]; then break; fi
	# Enforced start and stop time should only run once, then it should be auto.
	# it doesn't (normally) make sense to run 4-ever with static START and/or STOP.
	# Note: calling with args nothing/null/0 = "auto" date/time.
	if [ ! -z $STARTTS ]; then
		echo "setting null"
		STARTTS=''
	fi
	if [ ! -z $STOPTS ]; then
		STOPTS=''
	fi
	echo "Kill me with CTRL+C (PID: $$)"
	sleep 5
done

echo "OK, we're done here!"
