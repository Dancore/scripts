#!/bin/bash
##########################################################################
ABOUT="Script for syncing many and large log files being updated in realtime."
# Assumes that the logfiles follow a certain format with date and time etc
# in the file name.
# ------------------------------------------------------------------------
# 2014-08-11 Dan Kopparhed
##########################################################################
THISFILE=${0##*/}
args=("$@")
SYSTZ="CEST"
LOCALTZ=$(date +%Z)
LOGPATH="./logfiles"
CMD_CLEANDB="./cleanupdb.pl"
CMD_RSYNC="./rsync.pl"
CMD_CSV2DB="./csv2db.pl"

##########################################################################
f_usage()
{
	cat <<TXT
 $ABOUT
 Usage: ${THISFILE}
TXT
}
##########################################################################
# Make sure the TZ is correct to avoid the TZ-bug
if [ $LOCALTZ != $SYSTZ ]; then
	SETTZ="TZ=$SYSTZ"
else
	echo "Sys TZ == local TZ"
fi

LASTMIN=-1
echo "Starting"
echo "Clean up log files"
# $(rm $LOGPATH/*.csv)
echo "Clean up DB"
$CMD_CLEANDB

# --------------------------------------------------------
# --------------------------------------------------------
# If enforcing START/saved and END/current times
# Note: nothing/null/0 = "auto" date/time:
STARTTS=$($SETTZ date -d "2014-08-12 16:51:01" +%s)
ENDTS=$($SETTZ date -d "2014-08-12 17:01:01" +%s)
# --------------------------------------------------------
if [ ! -z $STARTTS ] || [ ! -z $ENDTS ]; then
	echo "Enforcing initial START/STOP times $STARTTS $ENDTS"
	$CMD_CSV2DB $STARTTS $ENDTS
fi
# --------------------------------------------------------

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

