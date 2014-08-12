#!/bin/bash
##########################################################################
ABOUT="Script for syncing many and large log files being updated in realtime."
# Assumes that the logfiles follow a certain format with date and time etc
# in the file name.
# ------------------------------------------------------------------------
# 2014-08-11 Dan Kopparhed
##########################################################################
THISFILE=${0##*/}
SYSTZ="CEST"
SERVER="TBD"
RPATH="./logfiles"
LPATH="./"
args=("$@")
##########################################################################
f_usage()
{
	cat <<TXT
 $ABOUT
 Usage: ${THISFILE}
TXT
}
##########################################################################
# OBS Make sure the TZ is correct if using this:
# Figure out the correct dates (taking the real calendar into account):
# CURRDATE=$(TZ=$SYSTZ date +%Y%m%d)
# CURRTIME=$(TZ=$SYSTZ date +%R)
# CURRTS=$(TZ=$SYSTZ date +%s)
# PREVTS=$(($CURRTS - 86399))
# PREVMIN=$(($CURRTS - 59))
# PREVTIME=$(TZ=$SYSTZ date -d @$PREVMIN +%R)
# PREVDATE=$(TZ=$SYSTZ date -d @$PREVTS +%Y%m%d)

CMD_RSYNC=""
CMD_CSV2DB="./csv2db.pl"
CMD_CLEANDB="./cleandb.pl"

LASTMIN=-1

echo "Clean up log files"
# $(rm ./*.csv)
echo "Clean up DB"
./cleanupdb.pl

echo "Starting loop"
# enter eternal loop:
for (( ; ; ))
do
	NEWMIN=$(TZ=$SYSTZ date +%M)
	if [ $NEWMIN -ne $LASTMIN ]; then
		LASTMIN=$NEWMIN
		SEC=$(TZ=$SYSTZ date +%S)
		echo "NEW minute started $LASTMIN:$SEC"
		echo "calling rsync"
		# $($CMD_RSYNC)
		echo "calling csv2db"
		# ./csv2db.pl 1405585141 1405632661 # testing
		./csv2db.pl
	fi
	echo "Kill me with CTRL+C."
	sleep 5
done

