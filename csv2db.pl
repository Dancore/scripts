#!/usr/bin/perl -w
# Parse CSV files with latency measurements, then recalculate for a certain granualarity
# (currently per minute). The data unit is then submitted to a PgSQL DB.
# Or; Simply push each line into a database for future processing and presentation.

use strict;
use warnings;
use DBI;

my $configuration = 'configuration.pl';
my $localconfiguration = 'configuration.local.pl';

if (-f $configuration) { require "$configuration"; }
else { print "ERROR: Configuration file not found. Quitting.\n"; exit 1; }
if (-f $localconfiguration) { require "$localconfiguration"; }
else { print "INFO: Local configuration file not found. Trying anyway.\n"; }
# import the settings from config into this (main) namespace/package:
our ($do_period_calc, $dirpath, $database_name, $database_user, $database_password, $database_host, $database_table);

# Database handle object:
my $dbh;

# period data structure
my %period = (
	samples => 0,
	tx => 0,
	ackavg => 0,
	avg => 0,
	max => 0,
	min => 0
	);

sub period_reset
{
	foreach my $k (keys %period) {
		$period{$k} = 0;
	}
	$period{min} = 9999999;
}

sub period_calculate
{
	my ($ntx, $avg, $max, $min) = @_;
	$period{samples}++;
	$period{tx} += $ntx;
	$period{ackavg} += $avg;
	if ($max > $period{max}) {$period{max} = $max;}
	if ($min < $period{min}) {$period{min} = $min;}
	$period{avg} = $period{ackavg} / $period{samples};
}

# report one completed period:
sub period_report
{
	# my $self = shift;
	my ($date, $lasthour, $lastminute, $lastsecond) = @_;
	print " GOT date $date $lasthour:$lastminute \n";
	print "nr of samples during period ($lasthour:$lastminute:$lastsecond) was: " . $period{samples} . "\n";
	print "nr of TX during period was: " . $period{tx} . "\n";
	print "avg of period was: "; printf("%.2f\n", $period{avg});
	print "max of period was: " . $period{max} . "\n";
	print "min of period was: " . $period{min} . "\n";
	# print " self is $self \n";

	# Insert period report into DB:
	my $sth = $dbh->prepare("INSERT INTO $database_table(date,txavg,txmax,txmin,ntx) VALUES (?,?,?,?,?)");
	$sth->execute("$date $lasthour:$lastminute:00", $period{avg}, $period{max}, $period{min}, $period{tx});
	# $dbh->commit;		# required unless AutoCommit is set.
}

# send one line to the DB:
sub line2db
{
	my ($T, $tcode, $txid, $avg, $max, $min, $ntx, $gw, $tapid) = @_;
	if (!$gw) { $gw = "n/a"; }
	if (!$tapid) { $tapid = 0; }
	# print " GOT date $T, $tcode, $txid, nTX: $ntx, avg: $avg, max: $max, min: $min, gw: $gw, tapid: $tapid\n";

	# Insert line into DB:
	my $sth = $dbh->prepare("INSERT INTO $database_table(datetime_col,usercode,transaction_name,avg_resp,max_resp,min_resp,nbr_transactions,gateway,tap_instance) VALUES (?,?,?,?,?,?,?,?,?)");
	$sth->execute($T, $tcode, $txid, $avg, $max, $min, $ntx, $gw, $tapid);
}

sub clear_table2
{
	# empty table when re-running test, avoid filling the DB with repeated data:
	my $sth = $dbh->prepare("DELETE FROM $database_table");
	$sth->execute;
}

sub clear_table
{
	# empty table when re-running test, avoid filling the DB with repeated data:
	my $sth = $dbh->prepare("DELETE FROM $database_table");
	$sth->execute;
	$sth = $dbh->prepare("ALTER SEQUENCE id_seq RESTART WITH 1");
	$sth->execute;
}

sub ConnectDB
{
	# print "Trying to establish DB connection\n";
	# DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port;options=$options;tty=$tty", "$username", "$password");
	$dbh = DBI->connect("DBI:Pg:dbname=$database_name;host=$database_host", $database_user, $database_password, {RaiseError => 1, AutoCommit => 0})
	or die "ERROR: Failed to connect to database: $DBI::errstr\n";
}
###################################################################################

# print "Trying to open dir '$dirpath'\n";
opendir(DIR, $dirpath) or die "ERROR: No such directory '$dirpath'. Quitting.\n";

# Establish DB connection:
ConnectDB;
print "INFO: Successfully connected to database\n";

if ($do_period_calc) {
	clear_table;
}
else {
	clear_table2;
}

while (my $filename = readdir(DIR))
{
	my $thefile;
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

	if ($do_period_calc)
	{
		while (my $line = <$thefile>)
		{
			chomp $line;
			# Some sanity checks:
			if ((!defined $line) || ($line eq "") || ($line eq " ") || (length($line) < 40)) {
				print "WARNING: Failed to read line $. in file '$filename' \n";
				next;
			}
			my ($T, $tcode, $txid, $avg, $max, $min, $ntx) = (split /;/, $line);
			($date, my $time) = split(/ /, $T);
			my ($hour, $minute, $second) = (split /:/, $time);

			# Detecting start of new measurement period (eg a new minute):
			if (($hour != $lasthour ) or ($minute != $lastminute)) {
				if($. > 2) {	# don't report before at least the first row/line (after title) is calc'd.
					period_report($date, $lasthour, $lastminute, $lastsecond);
				}
				period_reset;
			}
			period_calculate($ntx, $avg, $max, $min);

			$lasthour = $hour;
			$lastminute = $minute;
			$lastsecond = $second;
			$linesparsed++;
		}
		# One last measurment period considered to end with the end of the log file.
		period_report($date, $lasthour, $lastminute, $lastsecond);
	}
	else
	{
		while (my $line = <$thefile>)
		{
			chomp $line;
			# Some sanity checks:
			if ((!defined $line) || ($line eq "") || ($line eq " ") || (length($line) < 40)) {
				print "WARNING: Failed to read line $. in file '$filename' (skipping it)\n";
				next;
			}
			my ($T, $tcode, $txid, $avg, $max, $min, $ntx) = (split /;/, $line);
			line2db($T, $tcode, $txid, $avg, $max, $min, $ntx);
			$linesparsed++;
		}
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
