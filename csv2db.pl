#!/usr/bin/perl -w
# Parse CSV and simply push each line into a database for future processing and presentation.

use strict;
use warnings;
use DBI;
use POSIX qw(strftime);
# For execution performance measurements:
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

my $configuration = 'configuration.pl';
my $localconfiguration = 'configuration.local.pl';

if (-f $configuration) { require "$configuration"; }
else { print "ERROR: Configuration file not found. Quitting.\n"; exit 1; }
if (-f $localconfiguration) { require "$localconfiguration"; }
else { print "INFO: Local configuration file not found. Trying anyway.\n"; }
# import the settings from config into this (main) namespace/package:
our ($do_period_calc, $dirpath, $database_name, $database_user, $database_password, $database_host, $database_table, $perflogfilename);

# Database handle object:
my $dbh;
my $sth;

my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
# my @days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
# hash index for looking up month number by month name:
my %imonths;
@imonths{@months} = (1..($#months+1));
# print "test $imonths{\"Jan\"} $imonths{\"Dec\"} \n"; exit;

my $curryear = strftime "%Y", localtime;
my $currmonth = strftime "%m", localtime;
my $currday = strftime "%d", localtime;
my $currdate = $curryear.$currmonth.$currday;
my $prevyear = strftime "%Y", localtime(time() - 86400);
my $prevmonth = strftime "%m", localtime(time() - 86400);
my $prevday = strftime "%d", localtime(time() - 86400);
my $prevdate = $prevyear.$prevmonth.$prevday;
# my $currtime = strftime "%H:%M:%S", localtime;
my $currhour = strftime "%H", localtime;
my $currminute = strftime "%M", localtime;
my $prevtime = strftime "%H:%M", localtime(time() - 60);
print "Current DATE&TIME: $currdate $currhour$currminute Epoc: ".time()."\n";
print "Previous DATE&TIME: $prevdate $prevtime \n";
$currmonth = 07; #testing
$currday = 17; #testing
$prevday = 16; #testing
$currhour = 10; #testing
$currminute = 20; #testing
$currdate="20140717"; # testing
$prevdate="20140716"; # testing

my $database_table_latest = 'taplat_latest';

# Remember what minute we have processed up to, so we can avoid doing it again:
sub setlastdbtime
{
	# my $sth = $dbh->prepare("UPDATE $database_table_latest SET timestamp=? WHERE id=1");
	my $sth = $dbh->prepare("DELETE FROM $database_table_latest");
	$sth->execute;
	$sth = $dbh->prepare("INSERT INTO $database_table_latest VALUES (?,?)");
	$sth->execute(1, $_[0]);
	$sth->finish;
}
sub getlastdbtime
{
	my $sth = $dbh->prepare("SELECT * FROM $database_table_latest");
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
my $lastts = getlastdbtime;
my $lasthour = strftime "%H", localtime($lastts);
my $lastminute = strftime "%M", localtime($lastts);
print "Fetched last time: $lastts ($lasthour:$lastminute) \n";
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
	my $linedate = 0;
	my $linesparsed = 0;
	my $linessaved = 0;
	my ($linehour, $lineminute, $linesecond) = 0;

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
		($linedate, my $linetime) = split(/ /, $T);
		my ($lineday, $linemonth, $lineyear) = (split /-/, $linedate);
		$linemonth = $imonths{$linemonth}; # convert to month number
		# We only care about "fresh" data:
		next unless ($lineyear == $curryear || $lineyear == $prevyear);
		next unless ($linemonth == $currmonth || $linemonth == $prevyear);
		next unless ($lineday == $currday || $lineday == $prevyear);

		($linehour, $lineminute, $linesecond) = (split /:/, $linetime);
		# Pick up where we left off, i.e. skip the lines we already saved:
		if ($linehour < $lasthour && $lineminute <= $lastminute) {next;}
		# Only save completed minutes. If the log has caught up with current time,
		# it means we have reached the limit for now:
		if ($linehour >= $currhour && $lineminute >= $currminute) {last;}

		$t0 = [gettimeofday];
		line2db($T, $tcode, $txid, $avg, $max, $min, $ntx);
		$t1 = [gettimeofday];
		$t0_t1 = tv_interval($t0, $t1);
		$perfmax = Max($t0_t1, $perfmax);
		$perfmin = Min($t0_t1, $perfmin);
		$linessaved++;
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

	setlastdbtime(time());
	# finally, commit all the lines, if we survived:
	$dbh->commit; # required unless AutoCommit is set.
	if ($linesparsed > 0) {
		print "INFO: successfully saved $linessaved lines of $. in file '$filename'\n";
	}
	close $thefile;
}

# Housekeeping:
$dbh->disconnect;
closedir(DIR);
close $perflogfile;
