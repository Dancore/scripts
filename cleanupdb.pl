#!/usr/bin/perl -w
# cleanup DB

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
our ($do_period_calc, $dirpath, $database_name, $database_user, $database_password, $database_host,
	$database_table, $perflogfilename, $systemtimezone);

my $dbh;

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

ConnectDB;
clear_table;
$dbh->commit;

1;
