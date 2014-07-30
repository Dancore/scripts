#!/usr/bin/perl -w
# Read and parse tap lat files
#

#use strict;

print "starting\n";

$filename = "test.csv";

open (FILE, $filename) or die "Failed to open file '$filename' \n";

my $title = <FILE>;	# first line expected to be title line
my $lasthour = 0, $lastminute = 0, $lastsecond = 0, $periodavg = 0;
my $periodsamples = 0, $periodtx = 0, $periodavg = 0, $periodmax = 0, $periodmin = 0;

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

	# Detecting start of new measurement period (eg a new minute):
	if (($hour != $lasthour ) or ($minute != $lastminute)) {
		# print $lastsecond ." new minute ". $second ."\n";
		# print "nr of transfers was: ". $nrtx. "\n";
		print "nr of samples during period ($lasthour:$lastminute) was: " . $periodsamples . "\n";
		print "nr of TX during period was: " . $periodtx . "\n";
		print "avg of period was: "; printf("%.2f\n", $periodavg);
		#print "avg of period was: " . $periodavg . "\n";
		print "max of period was: " . $periodmax . "\n";
		print "min of period was: " . $periodmin . "\n";
		$periodtx = 0; $avgs = 0;
		$periodmax = 0; $periodmin = 9999999;
		$periodavg = 0;
		$periodsamples = 0;
	}
	$periodtx += $ntx;
	$avgs += $avg;
	$periodsamples++;
	$periodavg = $avgs / $periodsamples;
	if ($max > $periodmax) {$periodmax = $max;}
	if ($min < $periodmin) {$periodmin = $min;}

	$lasthour = $hour;
	$lastminute = $minute;
	$lastsecond = $second;
}
# One last measurment period considered to end with the end of the log file.

close FILE;
