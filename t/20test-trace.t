#!/usr/bin/env perl

use warnings;
use strict;

use File::Spec;
use File::Basename qw(dirname);
use lib dirname(__FILE__);
use Helper;
use Test::More 'no_plan';

my $full_cmdfile = File::Spec->catfile(dirname(__FILE__), 'data', 'trace1.cmd');
my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    if ($line =~ /.. \(.+\:\d+\)/) {
		$line =~ s/\((?:.*\/)?(.+\:\d+)\)/($1)/;
	    }
	    last if (0 == index($line, '-- (Temp.pm:'));
	    push @result, $line;
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    no_cmdfile => 1,
    run_opts => " --trace --no-highlight -nx --command $full_cmdfile"
};

my $test_prog = File::Spec->catfile(dirname(__FILE__), qw(.. example gcd.pl));
Helper::run_debugger("$test_prog 3 5", 'trace1.cmd', undef, $opts);
$opts->{no_cmdfile} = 0;
$opts->{run_opts}   = " --no-highlight --nx --basename --command $full_cmdfile";
Helper::run_debugger("$test_prog 3 5", 'trace2.cmd', undef, $opts);
