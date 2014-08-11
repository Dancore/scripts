#!/usr/bin/perl -w
# Parse CSV files with latency measurements, then recalculate for a certain granualarity
# (currently per minute). The data unit is then submitted to a PgSQL DB.
# Or; Simply push each line into a database for future processing and presentation.

use strict;
use warnings;
use DBI;
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

# send one line to the DB:
sub line2db
{
	my ($T, $tcode, $txid, $avg, $max, $min, $ntx, $gw, $tapid) = @_;
	if (!$gw) { $gw = "n/a"; }
	if (!$tapid) { $tapid = 0; }
	# print " GOT date $T, $tcode, $txid, nTX: $ntx, avg: $avg, max: $max, min: $min, gw: $gw, tapid: $tapid\n";

	# Insert line into DB:
	my $sth = $dbh->prepare("INSERT INTO $database_table VALUES (?,?,?,?,?,?,?,?,?)");
	$sth->execute($T, $tcode, $txid, $avg, $max, $min, $ntx, $gw, $tapid);
}

sub clear_table
{
	# empty table when re-running test, avoid filling the DB with repeated data:
	my $sth = $dbh->prepare("DELETE FROM $database_table");
	$sth->execute;
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
clear_table;
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

	# only csv files:
	next unless (-f "$dirpath/$filename");
	next unless ($filename =~ m/\.csv$/);

	# print "Trying to read csv file '$filename'\n";
	if (!open ($thefile, '<:encoding(utf8)', $dirpath."/".$filename)) {
		print "ERROR: Failed to open file '$filename'.\n";
		next;
	}

	my $title = <$thefile>;	# first line expected to be title line
	my $lasthour = 0;
	my $lastminute = 0;
	my $lastsecond = 0;
	my $date = 0;
	my $linesparsed = 0;

	$ft0 = [gettimeofday];
	while (my $line = <$thefile>)
	{
		chomp $line;
		# Some sanity checks:
		if ((!defined $line) || ($line eq "") || ($line eq " ") || (length($line) < 40)) {
			print "WARNING: Failed to read line $. in file '$filename' (skipping it)\n";
			next;
		}
		my ($T, $tcode, $txid, $avg, $max, $min, $ntx) = (split /;/, $line);
		$t0 = [gettimeofday];
		line2db($T, $tcode, $txid, $avg, $max, $min, $ntx);
		$t1 = [gettimeofday];
		$t0_t1 = tv_interval($t0, $t1);
		$perfmax = Max($t0_t1, $perfmax);
		$perfmin = Min($t0_t1, $perfmin);
		$linesparsed++;
	}
	$ft1 = [gettimeofday];
	$perffile = tv_interval($ft0, $ft1);
	if( $perffile > 0.00005 ) {
		print "time $startstamp, perffile $perffile s\n";
		print { $perflogfile } "$startstamp; $perffile; $.; ";

		if( $perfmax > 0) {
			print "line2db MAX $perfmax s, MIN $perfmin s\n";
			print { $perflogfile } "$perfmax; $perfmin; ";
		}
		print { $perflogfile } "\n";
	}

	# finally, commit all the lines, if we survived:
	$dbh->commit; # required unless AutoCommit is set.
	if ($linesparsed > 0) {
		print "INFO: successfully read lines $linesparsed of $. in file '$filename'\n";
	}
	close $thefile;
}

# Housekeeping:
$dbh->disconnect;
closedir(DIR);
close $perflogfile;
