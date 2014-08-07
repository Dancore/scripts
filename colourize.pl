#!/usr/bin/perl -n
# Found this nice little script at http://unix.stackexchange.com/questions/56282/colourful-terminal-or-console
# 2014-08-07

BEGIN {
	$exp = shift @ARGV;
	$color = shift @ARGV;
	die "Use: colourize regexp colour" unless $color;
}

if (/$exp/) {
	print"\e[${color}m";
}

print;

if (/$exp/) {
	print "\e[0m";
}
