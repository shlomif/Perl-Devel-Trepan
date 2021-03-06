# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockbcpan.org>

use warnings; no warnings 'redefine'; no warnings 'once';
use lib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Aliases;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "show aliases";
our $HELP         = <<"EOH";
$CMD [NAME1 NAME2 ...] 

If aliases names are given, show their definition. If left blank, show
all alias names
EOH

our $MIN_ABBREV = length('al');
our $SHORT_HELP = "Show defined aliases";

# sub complete($$) {
# {
#     my ($self, $prefix) = @_;
#     my @cmds = sort keys %{$proc->{aliases}};
#     Trepan::Complete.complete_token(@cmds, $prefix);
# }

sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args;
    if (scalar(@args) > 2) {
    	shift @args; shift @args;
    	for my $alias_name (@args) {
    	    if (exists $proc->{aliases}{$alias_name}) {
    		my $msg = sprintf "%s: %s", $alias_name, $proc->{aliases}{$alias_name};
    		$proc->msg($msg);
    	    } else {
    		$proc->msg("$alias_name is not a defined alias");
    	    }
    	}
    } else {
	my @aliases = keys %{$proc->{aliases}};
	if (scalar @aliases == 0) {
	    $proc->msg("No aliases defined.");
	} else {
	    $proc->section("List of alias names currently defined:");
	    my @cmds = sort @aliases;
	    $proc->msg($self->{cmd}->columnize_commands(\@cmds));
	}
   }
}

unless(caller) {
    # Demo it.
    # require_relative '../../mock';
    # my $cmd = MockDebugger::sub_setup(__PACKAGE__);
    # my $cmd->run($cmd->{prefix} + %w(u foo));
}

1;
