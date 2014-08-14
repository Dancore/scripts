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

my $scriptstarttime = [gettimeofday];

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
my $currhour = strftime "%H", localtime($currts);
my $currminute = strftime "%M", localtime($currts);

print "Current DATE&TIME: $currdate $currhour:$currminute Epoc: ".$currts."\n";

my $database_table_savedtime = 'taplat_savedtime';
###################################################################################
# Remember what minute we have processed up to, so we can avoid doing it again:
sub setdb_savedts
{
	my $sth = $dbh->prepare("DELETE FROM $database_table_savedtime");
	$sth->execute;
	$sth = $dbh->prepare("INSERT INTO $database_table_savedtime VALUES (?,?)");
	$sth->execute(1, $_[0]);
	$sth->finish;
}
sub getdb_savedts
{
	my $sth = $dbh->prepare("SELECT * FROM $database_table_savedtime LIMIT 1");
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
	if (!$gw) { $gw = "n/a"; }	# if no gateway info was provided
	if (!$tapid) { $tapid = 0; }
	# Insert line into DB:
	$sth->execute($T, $tcode, $txid, $avg, $max, $min, $ntx, $gw, $tapid);
}

# Clear out table when re-running test, avoid filling the DB with repeated data:
sub clear_table
{
	# TRUNCATE quickly removes all rows from a set of tables. It has the same effect as an
	# unqualified DELETE on each table, but since it does not actually scan the tables it is faster.
	# Furthermore, it reclaims disk space immediately, rather than requiring a subsequent VACUUM
	# operation. This is most useful on large tables.

	my $sth = $dbh->prepare("TRUNCATE $database_table");
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

# simple MIN/MAX algos that returns min/max of two values provided:
sub Max { if($_[0] > $_[1]) {return $_[0];} return $_[1]; }
sub Min { if($_[0] < $_[1]) {return $_[0];} return $_[1]; }

###################################################################################

# print "Trying to open dir '$dirpath'\n";
opendir(DIR, $dirpath) or die "ERROR: No such directory '$dirpath'. Quitting.\n";

my $perflogfile;
# print "Trying to open log file '$perflogfilename'\n";
if (!open ($perflogfile, '>>:encoding(utf8)', $perflogfilename)) {
	print "WARNING: Failed to open logfile '$perflogfilename'.\n";
}

# Establish DB connection:
ConnectDB;
# print "INFO: Successfully connected to database\n";
if(!$savedts) {
	$savedts = getdb_savedts;
}
my $savedyear = strftime "%Y", localtime($savedts);
my $savedmonth = strftime "%m", localtime($savedts);
my $savedday = strftime "%d", localtime($savedts);
my $savedhour = strftime "%H", localtime($savedts);
my $savedminute = strftime "%M", localtime($savedts);
# my $saveddate = strftime "%F", localtime($savedts);
my $saveddate = $savedyear.$savedmonth.$savedday;
print "INFO: Got saved time $savedts ($saveddate $savedhour:$savedminute) \n";
# clear_table;
line2db_prepare;
my ($t0, $t1, $t0_t1, $perfmax, $perfmin, $perffilemax, $perffilemin, $ft0, $ft1, $perffile, $filestartstamp) = 0;
my $anylinessaved = 0;
my $numberoffiles = 0;

while (my $filename = readdir(DIR))
{
	my $thefile;
	$perfmax = 0;
	$perfmin = 99999999;
	$perffilemax = 0;
	$perffilemin = 99999999;
	my ($filestarttime_s, $filestarttime_us) = gettimeofday();
	$filestartstamp = "$filestarttime_s.$filestarttime_us";

	next unless (-f "$dirpath/$filename");
	next unless ($filename =~ m/\.csv$/);
	# Disable matching dates in filename because it proved to be unreliable:
	# if ($filename !~ m/$currdate/ && $filename !~ m/$prevdate/ ) {next;}

	$numberoffiles++;
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
			# This warning can be "noisy", because all logs I've seen has a bad last line:
			# TODO? Only warn if it is NOT last line.
			# print "WARNING: Failed to read line $. in file '$filename' (skipping it)\n";
			next;
		}
		$linesparsed++;
		my ($T, $tcode, $txid, $avg, $max, $min, $ntx) = (split /;/, $line);
		($linedate, $linetime) = split(/ /, $T);
		($lineday, $linemonth, $lineyear) = (split /-/, $linedate);
		# Ignore the future :)
		if ($lineyear > $curryear) {last;}
		$linemonth = $imonths{$linemonth}; # convert to month number
		if ($linemonth > $currmonth) {last;}
		if ($lineday > $currday) {last;}

		# Ignore all dates already processed:
		if ($lineyear < $savedyear) {next;}
		if ($linemonth < $savedmonth) {next;}
		if ($lineday < $savedday) {next;}

		# If we have caught up with the current date, we need to increase resolution to minutes:
		($linehour, $lineminute, $linesecond) = (split /:/, $linetime);
		if(($lineyear == $curryear) && ($linemonth == $currmonth) && ($lineday == $currday)) {
			# Only save completed minutes. If the log has caught up with current time,
			# it means we have reached the practical limit for now:
			if ($linehour > $currhour) {last;}
			elsif ($linehour == $currhour) {
				if ($lineminute >= $currminute) {last;}
			}
		}
		# If we are processing the saved date, check the minutes
		if(($lineyear == $savedyear) && ($linemonth == $savedmonth) && ($lineday == $savedday)) {
			# Pick up where we left off, i.e. skip the lines we already saved:
			if ($linehour < $savedhour) {next;}
			elsif ($linehour == $savedhour) {
				if ($lineminute <= $savedminute) {next;}
			}
		}
		# else this must be a complete, unprocessed minute.
		# print "Found new minute stats for $lineminute:$linehour ($linedate).\n";

		# get the gw and tapid data from the filename:
		my($part1, $part2, $tapid, $gateway, $rest) = split /_/, $filename, 5;
		$t0 = [gettimeofday];
		line2db($T, $tcode, $txid, $avg, $max, $min, $ntx, $gateway, $tapid);
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

	if( $linessaved > 0 ) {
		# print "Time: $filestartstamp, perffile: $perffile s, $linessaved of $. ";
		print { $perflogfile } "$filestartstamp; $perffile; $.; $linessaved; ";

		if( $perfmax > 0) {
			# print "line2db MAX: $perfmax s, MIN: $perfmin s";
			print { $perflogfile } "$perfmax; $perfmin; ";
		}
		# print "\n";
		print { $perflogfile } "\n";
	}

	if ($lasthour > 0) {
		# finally, commit all the lines, if we survived:
		$dbh->commit; # required unless AutoCommit is set.
	}
	if ($linessaved > 0) {
		print "INFO: successfully saved $linessaved lines of $linesparsed ($.) in file '$filename'\n";
		$anylinessaved += $linessaved;
	}
	else {
		print "INFO: NO lines saved out of $linesparsed ($.) in file '$filename'\n";
	}
	close $thefile;
}

# my ($scriptstoptime_s, $scriptstoptime_us) = gettimeofday();
my $scriptstoptime = [gettimeofday];
my $scriptruntime = tv_interval($scriptstarttime, $scriptstoptime);

# If at least one csv file was processed, consider all logs parsed up to "T-1":
if ($numberoffiles > 0) {
	my $linespersec = $anylinessaved/$scriptruntime;
	print "INFO: Finished $anylinessaved lines from $numberoffiles files in '$dirpath' after $scriptruntime s ";
	printf("(%.3f l/s)\n", $linespersec);
	my $savedts = $currts - 60; # last complete minute
	print "INFO: Setting saved time to $savedts (".strftime("%Y-%m-%d %H:%M:%S", localtime($savedts)).")\n";
	setdb_savedts($savedts);
	$dbh->commit;
}

# Housekeeping:
$dbh->disconnect;
closedir(DIR);
close $perflogfile;
