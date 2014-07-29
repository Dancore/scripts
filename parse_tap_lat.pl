#!/usr/bin/perl -w
# Read and parse tap lat files
#

#use strict;

print "starting\n";

$filename = "test.csv";

open (FILE, $filename) or die "Failed to open file '$filename' \n";

my $title = <FILE>;	# first line expected to be title line
my $lasthour = 0, $lastminute = 0, $lastsecond = 0, $periodavg = 0;

while(my $line = <FILE>)
{
	chomp $line;
	# print "'$line'";
	# print " len ". length($line);
	if ((!defined $line) || ($line eq "") || ($line eq " ") || (length($line) < 40)) {
		print "nothing";
		exit;
	}
	my ($T, $tcode, $txid, $avg, $max, $min, $ntx) = (split /;/, $line);
	my ($date, $time) = split(/ /, $T);
	my ($hour, $minute, $second) = (split /:/, $time);
	# print $time." ".$second."\n";


	# Detecting start of new period (eg a new minute):
	if (($lasthour != $hour) and ($lastminute != $minute)) {
		print $lastsecond ." new minute ". $second ."\n";
		# print "nr of transfers was: ". $nrtx. "\n";
		print "avg of period was: " . $periodavg . "\n";
		$nrtx = 0; $avgs = 0; $maxs = 0; $mins = 0;
		$periodavg = 0;
	}

	$nrtx += $ntx;
	$avgs += $avg;
	$maxs += $max;
	$mins += $min;
	$periodavg = $avgs / $nrtx;

	$lasthour = $hour;
	$lastminute = $minute;
	$lastsecond = $second;
}

close FILE;
