#!/usr/bin/perl -w
# Parse CSV files with latency measurements, then recalculate for a certain granualarity
# (currently per minute). The data unit is then submitted to a PgSQL DB.
#

use strict;
use DBI;

my $filename = "test.csv";
#$filename = "badfile.csv";
my $database = "test";
my $dbuser = "testuser";
my $dbpassword = "";
# $dbhost = "";
# $dbport = "";

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
	my $sth = $dbh->prepare("INSERT INTO taplat(date,txavg,txmax,txmin,ntx) VALUES (?,?,?,?,?)");
	$sth->execute("$date $lasthour:$lastminute:00", $period{avg}, $period{max}, $period{min}, $period{tx});
	# $dbh->commit;		# required unless AutoCommit is set.
}

print "Trying to read csv file '$filename'\n";
open (my $thefile, '<:encoding(utf8)', $filename) or die "ERROR: Failed to open file '$filename' \n";

# Establish DB connection:
print "Trying to establish DB connection\n";
# DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port;options=$options;tty=$tty", "$username", "$password");
$dbh = DBI->connect("dbi:Pg:dbname=$database", $dbuser, $dbpassword, {RaiseError => 1, AutoCommit => 1})
	or die "ERROR: Failed to connect to database: $DBI::errstr\n";

# empty table when re-running test, avoid filling the DB with repeated data:
my $sth = $dbh->prepare("DELETE FROM taplat");
$sth->execute;
$sth = $dbh->prepare("ALTER SEQUENCE id_seq RESTART WITH 1");
$sth->execute;

my $title = <$thefile>;	# first line expected to be title line
my $lasthour = 0;
my $lastminute = 0;
my $lastsecond = 0;
my $date = 0;

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
}
# One last measurment period considered to end with the end of the log file.
period_report($date, $lasthour, $lastminute, $lastsecond);

# Housekeeping:
$dbh->disconnect;
close $thefile;
