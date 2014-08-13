#!/usr/bin/perl
# Rsync the requested files to the destination
#
# css_realtime_taplat_rsync.pl [days]
#
#
######
use strict;
use warnings;
use POSIX;
##Static config
my @dates;
my $days_back = $ARGV[0] || 2;
my $taplat_folder = $ARGV[1] || "/opt/omex/tom/tom/omn/cur/dat/";
##
##User config
my $gateways= "tx0600,tx0601,tx0602,tx0602"; ## Colon separeade list
##

calculate_dates();
run_rsync();

sub calculate_dates
{
	for (my $days = 0; $days <= $days_back-1;$days++)
	{
		my $timeelement = strftime "%Y%m%d",(localtime(time() - $days*24*60*60));
		print $timeelement."\n";
		push (@dates,$timeelement);
	}
}

sub run_rsync
{
	my @gateway_array = split (',',$gateways);
	foreach my $gate(@gateway_array)
	{
		foreach my $date (@dates)
		{
			my $command = "rsync -avz ".$gate.":".$taplat_folder.$date."*.csv ./";
			print $command ."\n";
			#system($command) == 0 || die "Failed to run rsync command: $command $! \n";
		}
	}
}

1;
