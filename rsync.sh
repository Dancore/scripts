#!/bin/bash
##########################################################################
ABOUT="Script for syncing many and large log files being updated in realtime."
# Assumes that the logfiles follow a certain format with date and time etc
# in the file name.
# ------------------------------------------------------------------------
# 2014-08-04 Dan Kopparhed
##########################################################################
THISFILE=${0##*/}
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

# Figure out the correct dates (taking the real calendar into account):
CURRDATE=$(date +%Y%m%d)
CURRTIME=$(date +%R)
CURRTS=$(date +%s)
PREVTS=$(($CURRTS - 86399))
PREVMIN=$(($CURRTS - 59))
PREVTIME=$(date -d @$PREVMIN +%R)
PREVDATE=$(date -d @$PREVTS +%Y%m%d)

echo "Syncing today ($CURRDATE) and yesterday ($PREVDATE)"
echo "Today: $(date), yesterday: $(date -d @$PREVTS)"
echo "This time: $CURRTIME, last minute: $PREVTIME"

# rsync -avz -e ssh user@server:/path ./
# Rsync logs from today and yesterday:
rsync -av $RPATH/*\_$CURRDATE\_*.csv $LPATH
rsync -av $RPATH/*\_$PREVDATE\_*.csv $LPATH

