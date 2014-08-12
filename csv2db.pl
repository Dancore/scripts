#!/usr/bin/perl -w
# Parse CSV and simply push each line into a database for future processing and presentation.

use strict;
use warnings;
use DBI;
use POSIX qw(strftime tzset);
# For "reversed" date conversion, from string to timestamp, with timelocal() and timegm():
use Time::Local;
# For execution performance measurements:
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

my $savedts = $ARGV[0];	# override saved time(stamp) with another to START from
my $currts = $ARGV[1]; # override current time(stamp) with another to END with

my $configuration = 'configuration.pl';
my $localconfiguration = 'configuration.local.pl';

if (-f $configuration) { require "$configuration"; }
else { print "ERROR: Configuration file not found. Quitting.\n"; exit 1; }
if (-f $localconfiguration) { require "$localconfiguration"; }
else { print "INFO: Local configuration file not found. Trying anyway.\n"; }
# import the settings from config into this (main) namespace/package:
our ($do_period_calc, $dirpath, $database_name, $database_user, $database_password, $database_host,
	$database_table, $perflogfilename, $systemtimezone);

# Database handle object:
my $dbh;
my $sth;

if(!$systemtimezone) {
	print "ERROR: system timezone setting missing from config. Quitting\n";
	exit;
}
my $localtimezone = strftime "%Z", localtime;
# my $localtzoffset = strftime "%z", localtime;
# print "was TZ: $localtimezone offset: $localtzoffset\n";
# Use system TZ. But if local TZ == system TZ, don't set it "again" or we get wrong time:
if($localtimezone ne $systemtimezone) {
	$ENV{TZ} = $systemtimezone;
}
# print "now TZ: ".strftime("%Z", localtime)." offset: ".strftime("%z", localtime)."\n";

my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
# my @days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
# hash index for looking up month number by month name:
my %imonths;
@imonths{@months} = (1..($#months+1));
# print "test $imonths{\"Jan\"} $imonths{\"Dec\"} \n"; exit;

if(!$currts) {$currts = time();}

# Prepare current date/time and the previous = the day before the current:
my $curryear = strftime "%Y", localtime($currts);
my $currmonth = strftime "%m", localtime($currts);
my $currday = strftime "%d", localtime($currts);
my $currdate = $curryear.$currmonth.$currday;
my $prevyear = strftime "%Y", localtime($currts - 86400);
my $prevmonth = strftime "%m", localtime($currts - 86400);
my $prevday = strftime "%d", localtime($currts - 86400);
my $prevdate = $prevyear.$prevmonth.$prevday;
# my $currtime = strftime "%H:%M:%S", localtime;
my $currhour = strftime "%H", localtime($currts);
my $currminute = strftime "%M", localtime($currts);
# my $prevtime = strftime "%H:%M", localtime(time() - 60);
# $currmonth = 07; #testing
# $currday = 17; #testing
# $prevday = 16; #testing
# $currhour = 11; #testing
# $currminute = 34; #testing
# $currdate="20140717"; # testing
# $prevdate="20140716"; # testing
print "Current DATE&TIME: $currdate $currhour:$currminute Epoc: ".$currts."\n";
# print "Previous DATE&TIME: $prevdate $prevtime \n";

my $database_table_savedtime = 'taplat_savedtime';
###################################################################################
# Remember what minute we have processed up to, so we can avoid doing it again:
sub setdb_savedts
{
	# my $sth = $dbh->prepare("UPDATE $database_table_savedtime SET timestamp=? WHERE id=1");
	my $sth = $dbh->prepare("DELETE FROM $database_table_savedtime");
	$sth->execute;
	$sth = $dbh->prepare("INSERT INTO $database_table_savedtime VALUES (?,?)");
	$sth->execute(1, $_[0]);
	$sth->finish;
}
sub getdb_savedts
{
	my $sth = $dbh->prepare("SELECT * FROM $database_table_savedtime");
	$sth->execute;
	my @row = $sth->fetchrow_array();
	$sth->finish;
	# print "row $#row \n";
	if($#row < 0) {return 0;}
	return $row[1];
}

# Separated DBI prepare call for increased performance:
sub line2db_prepare
{
	$sth = $dbh->prepare("INSERT INTO $database_table VALUES (?,?,?,?,?,?,?,?,?)");
}

# send one line to the DB:
sub line2db
{
	my ($T, $tcode, $txid, $avg, $max, $min, $ntx, $gw, $tapid) = @_;
	if (!$gw) { $gw = "n/a"; }
	if (!$tapid) { $tapid = 0; }
	# Insert line into DB:
	$sth->execute($T, $tcode, $txid, $avg, $max, $min, $ntx, $gw, $tapid);
}

sub clear_table
{
	# empty table when re-running test, avoid filling the DB with repeated data:
	my $sth = $dbh->prepare("DELETE FROM $database_table");
	$sth->execute;
	# print "Cleared table\n";
}

sub ConnectDB
{
	# print "Trying to establish DB connection\n";
	# DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port;options=$options;tty=$tty", "$username", "$password");
	$dbh = DBI->connect("DBI:Pg:dbname=$database_name;host=$database_host", $database_user, $database_password, {RaiseError => 1, AutoCommit => 0})
	or die "ERROR: Failed to connect to database: $DBI::errstr\n";
}

sub Max { if($_[0] > $_[1]) {return $_[0];} return $_[1]; }
sub Min { if($_[0] < $_[1]) {return $_[0];} return $_[1]; }

###################################################################################

# print "Trying to open dir '$dirpath'\n";
opendir(DIR, $dirpath) or die "ERROR: No such directory '$dirpath'. Quitting.\n";

my $perflogfile;
# print "Trying to open log file '$perflogfilename'\n";
if (!open ($perflogfile, '>>:encoding(utf8)', $perflogfilename)) {
	print "ERROR: Failed to open logfile '$perflogfilename'.\n";
}

# Establish DB connection:
ConnectDB;
print "INFO: Successfully connected to database\n";
if(!$savedts) {
	$savedts = getdb_savedts;
}
my $savedhour = strftime "%H", localtime($savedts);
my $savedminute = strftime "%M", localtime($savedts);
my $saveddate = strftime "%F", localtime($savedts);
print "Fetched saved time: $savedts ($saveddate $savedhour:$savedminute) \n";
clear_table;
line2db_prepare;
my ($t0, $t1, $t0_t1, $perfmax, $perfmin, $perffilemax, $perffilemin, $ft0, $ft1, $perffile, $startstamp) = 0;

while (my $filename = readdir(DIR))
{
	my $thefile;
	$perfmax = 0;
	$perfmin = 99999999;
	$perffilemax = 0;
	$perffilemin = 99999999;
	my ($starttime_s, $starttime_us) = gettimeofday();
	$startstamp = "$starttime_s.$starttime_us";

	# only csv files and only logfiles with "fresh" data:
	next unless (-f "$dirpath/$filename");
	next unless ($filename =~ m/\.csv$/);
	if ($filename !~ m/$currdate/ && $filename !~ m/$prevdate/ ) {next;}

	# print "Trying to read csv file '$filename'\n";
	if (!open ($thefile, '<:encoding(utf8)', $dirpath."/".$filename)) {
		print "ERROR: Failed to open file '$filename'.\n";
		next;
	}

	my $title = <$thefile>;	# first line expected to be title line
	my $linesparsed = 0;
	my $linessaved = 0;
	my ($linedate, $linetime) = 0;
	my ($lineday, $linemonth, $lineyear) = 0;
	my ($linehour, $lineminute, $linesecond) = 0;
	my ($lastday, $lastmonth, $lastyear) = 0;
	my ($lasthour, $lastminute) = 0;

	$ft0 = [gettimeofday];
	while (my $line = <$thefile>)
	{
		chomp $line;
		# Some sanity checks:
		if ((!defined $line) || ($line eq "") || ($line eq " ") || (length($line) < 40)) {
			print "WARNING: Failed to read line $. in file '$filename' (skipping it)\n";
			next;
		}
		$linesparsed++;
		my ($T, $tcode, $txid, $avg, $max, $min, $ntx) = (split /;/, $line);
		($linedate, $linetime) = split(/ /, $T);
		($lineday, $linemonth, $lineyear) = (split /-/, $linedate);
		$linemonth = $imonths{$linemonth}; # convert to month number
		# We only care about "fresh" data:
		next unless ($lineyear == $curryear || $lineyear == $prevyear);
		next unless ($linemonth == $currmonth || $linemonth == $prevmonth);
		next unless ($lineday == $currday || $lineday == $prevday);

		($linehour, $lineminute, $linesecond) = (split /:/, $linetime);
		# Only save completed minutes. If the log has caught up with current time,
		# it means we have reached the practical limit for now:
		if ($linehour > $currhour) {last;}
		elsif ($linehour == $currhour) {
			if ($lineminute >= $currminute) {last;}
		}
		# Pick up where we left off, i.e. skip the lines we already saved:
		if ($linehour < $savedhour) {next;}
		elsif ($linehour == $savedhour) {
			if ($lineminute <= $savedminute) {next;}
		}
		# else this must be a complete, unprocessed minute.
		# print "Found new minute stats for $lineminute:$linehour ($linedate).\n";

		$t0 = [gettimeofday];
		line2db($T, $tcode, $txid, $avg, $max, $min, $ntx);
		$t1 = [gettimeofday];
		$t0_t1 = tv_interval($t0, $t1);
		$perfmax = Max($t0_t1, $perfmax);
		$perfmin = Min($t0_t1, $perfmin);
		$linessaved++;
		# Last date and time sucessfully processed, taking things like month shifts into account:
		$lastyear = $lineyear;
		$lastmonth = $linemonth;
		$lastday = $lineday;
		$lasthour = $linehour;
		$lastminute = $lineminute;
	}
	$ft1 = [gettimeofday];
	$perffile = tv_interval($ft0, $ft1);

	if( $perffile > 0.00005 ) {
		print "Time: $startstamp, perffile: $perffile s, ";
		print { $perflogfile } "$startstamp; $perffile; $.; ";

		if( $perfmax > 0) {
			print "line2db MAX: $perfmax s, MIN: $perfmin s";
			print { $perflogfile } "$perfmax; $perfmin; ";
		}
		print "\n";
		print { $perflogfile } "\n";
	}

	# $lasthour = 10; $lastminute = 19; # testing - enforce this as saved minute
	# $lastyear = 2014; $lastmonth = 07; $lastday = 17; # testing
	if ($lasthour > 0) {
		# timelocal($sec,$min,$hour,$mday,$mon-1,$year);
		my $savedts = timelocal(1, $lastminute, $lasthour, $lastday, $lastmonth-1, $lastyear);
		print "Setting savedts to: $savedts ($lastyear $lastmonth $lastday $lasthour:$lastminute:01)\n";
		setdb_savedts($savedts);
		# finally, commit all the lines, if we survived:
		$dbh->commit; # required unless AutoCommit is set.
	}
	if ($linessaved > 0) {
		print "INFO: successfully saved $linessaved lines of $linesparsed ($.) in file '$filename'\n";
	}
	else {
		print "INFO: no lines saved out of $linesparsed ($.) in file '$filename'\n";
	}
	close $thefile;
}

# Housekeeping:
$dbh->disconnect;
closedir(DIR);
close $perflogfile;
