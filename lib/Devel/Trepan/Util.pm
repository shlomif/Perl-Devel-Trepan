# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
package Devel::Trepan::Util;

use strict;
use warnings;
use feature 'switch';

use vars qw(@EXPORT @ISA);
@EXPORT    = qw( hash_merge safe_repr uniq_abbrev extract_expression
                 parse_eval_suffix);
@ISA = qw(Exporter);

# Hash merge like Ruby has.
sub hash_merge($$) {
    my ($config, $default_opts) = @_;
    while (my ($field, $default_value) = each %$default_opts) {
	$config->{$field} = $default_value unless defined $config->{$field};
    };
    $config;
}

sub safe_repr($$;$)
{
    my ($str, $max, $elipsis) = @_;
    $elipsis = '... ' unless defined $elipsis;
    my $strlen = length($str);
    if ($max > 0 && $strlen > $max && -1 == index($str, "\n")) {
	sprintf("%s%s%s", substr($str, 0, $max/2), 
		$elipsis,  substr($str, $strlen+1-($max)/2));
    } else {
	$str;
    }
}

# name is String and list is an Array of String.
# If name is a unique leading prefix of one of the entries of list,
# then return that. Otherwise return name.
sub uniq_abbrev($$)
{ 
    my ($list, $name) = @_;
    my @candidates = ();
    for my $try_name (@$list) {
	push @candidates, $try_name if 0 == index($try_name, $name);
    }
    scalar @candidates == 1 ? $candidates[0] : $name;
}

# extract the "expression" part of a line of source code.
# 
sub extract_expression($)
{
    my $text = shift;
    if ($text =~ /^\s*(?:if|elsif|unless)\s*\(/) {
        $text =~ s/^\s*(?:if|elsif|unless)\s*\(//;
        $text =~ s/\s*\)\s*\{?\s*$//;
    } elsif ($text =~ /^\s*(?:until|while)\s*\(/) {
        $text =~ s/^\s*(?:until|while)\s*\(//;
        $text =~ s/\s*\)\{?\s*$//;
    } elsif ($text =~ /^\s*return\s+/) {
        # EXPRESSION in: return EXPRESSION
        $text =~ s/^\s*return\s+//;
        $text =~ s/;\s*$//;
    } elsif ($text =~ /^\s*my\s*(.+(\((?:.+)\s*\)\s*=.*);.*$)/) {
        # my (...) = ...;
	$text =~ s/^\s*my\s*(\((?:.+)\)\s*=.*)[^;]*;.*$/$1/;
    # } elsif ($text =~ /^\s*case\s+/) {
    #     # EXPRESSION in: case EXPESSION
    #     $text =~ s/^\s*case\s*//;
    # } elsif ($text =~ /^\s*def\s*.*\(.+\)/) {
    #     $text =~ s/^\s*sub\s*.*\((.*)\)/\(\1\)/;
    } elsif ($text =~ /^\s*[A-Za-z_][A-Za-z0-9_\[\]]*\s*=[^=>]/) {
        # RHS of an assignment statement.
        $text =~ s/^\s*[A-Za-z_][A-Za-z0-9_\[\]]*\s*=//;
    }
    return $text;
}

sub parse_eval_suffix($)
{
    my $cmd = shift;
    my $suffix = substr($cmd, -1);
    return ( index('%@$', $suffix) != -1) ? $suffix : '';
}

# Demo code
unless (caller) {
    my $default_config = {a => 1, b => 'c'};
    require Data::Dumper;
    import Data::Dumper;
    my $config = {};
    hash_merge $config, $default_config;
    print Dumper($config), "\n";

    $config = {
	term_adjust   => 1,
	bogus         => 'yep'
    };
    print Dumper($config), "\n";
    hash_merge $config, $default_config;
    print Dumper($config), "\n";

    my $string = 'The time has come to talk of many things.';
    print safe_repr($string, 50), "\n";
    print safe_repr($string, 17), "\n";
    print safe_repr($string, 17, ''), "\n";

    my @list = qw(disassemble disable distance up);
    uniq_abbrev(\@list, 'disas');
    print join(' ', @list), "\n";
    for my $name (qw(dis disas u upper foo)) {
	printf("uniq_abbrev of %s is %s\n", $name, 
	       uniq_abbrev(\@list, $name));
    }
    # ------------------------------------
    # extract_expression
    for my $stmt (
	'if (condition("if"))', 
	'if (condition("if")) {', 
	'if(condition("if")){', 
	'until (until_termination)',
	'until (until_termination){',
	'return return_value',
	'return return_value;',
	'nothing to be done',
	'my ($a,$b) = (5,6);',
	) {
	print extract_expression($stmt), "\n";
    }

    for my $cmd (qw(eval eval$ eval% eval@ evaluate% none)) {
	printf "parse_eval_suffix($cmd) => '%s'\n", parse_eval_suffix($cmd);
    }
}

1;
