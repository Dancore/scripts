#!/usr/bin/perl
# Rsync the requested files to the destination
#
# css_realtime_taplat_rsync.pl [days back]
# 2014-08-20 v1 - Inital creation done.
#
######
use strict;
use warnings;
use POSIX;
use Cwd qw();

##Static config
my @dates;
my $days_back = $ARGV[0] || 1;

##
##User config
my $taplat_folder = "/opt/omex/tom/tom/omn/cur/dat/"; #Remote folders where taplat is stored
my $taplat_processing_folder = "taplat"; #localt processing folder.
my $logfile_folder = "logfiles";
my $gateways= "UK03TOMTVBE31,UK03TOMTVGW06,UK03TOMTVGW07"; ## Colon separeade list "UK03TOMTVBE31,UK03TOMTVGW06,UK03TOMTVGW07"
##

#Loggstuff
my $directory = Cwd::cwd();
my $date = strftime "%Y%m%d",(localtime(time()));
unless (-d $logfile_folder)
	{
		mkdir $logfile_folder;
		print "Creating directory $logfile_folder\n";
		
	}
my $logfile = $directory."/".$logfile_folder."/"."rsync_".$date.".log";
open STDOUT, ">>", "$logfile" or die "$0: open: $!";
open STDERR, ">>&STDOUT"        or die "$0: dup: $!";



##Main Code
#Create taplat folder if not existing
unless (-d $taplat_processing_folder)
	{
		mkdir $taplat_processing_folder;
		print "Creating directory $taplat_processing_folder\n";
		
	}

calculate_dates()==0 || die "Filed in Calculate_dates $! \n";
run_rsync()==0 || die "Filed in run_rsync $! \n";;

exit 0;

#SCRIPT end

sub calculate_dates{

		for (my $days = 0; $days <= $days_back;$days++)
		{
		my $timeelement = strftime "%Y%m%d",(localtime(time() - $days*24*60*60));
		print $timeelement."\n";
		push (@dates,$timeelement);
		}
		
}

sub run_rsync{
	my @gateway_array = split (',',$gateways);
	
	
	foreach my $gate(@gateway_array)
	{
		foreach my $date (@dates)
		{		

		my $command = "rsync -avz ".$gate.":".$taplat_folder."*".$date."*.csv ./$taplat_processing_folder";
		print $command ."\n";
		system($command);
		
		}
		}
		
		
		
			
	}
	
	
	
	
