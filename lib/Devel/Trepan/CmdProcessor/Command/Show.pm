# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use lib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Show;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::SubMgr;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command;
use strict;
use vars qw(@ISA);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubcmdMgr);
use vars @CMD_VARS;

local $NAME = set_name();
our $HELP = <<"HELP";
Generic command for showing things about the debugger.  You can
give unique prefix of the name of a subcommand to get information
about just that subcommand.

Type ${NAME} for a list of ${NAME} subcommands and what they do.
Type "help ${NAME} *" for just a list of ${NAME} subcommands.
HELP

use constant CATEGORY => 'status';
use constant SHORT_HELP => 'Show parts of the debugger environment';
local $NEED_STACK     = 0;
$MAX_ARGS             = 1000;
$MIN_ARGS             = 0;

sub run($$) 
{
    my ($self, $args) = @_;
    my $first;
    if (scalar @$args > 1) {
	$first = lc $args->[1];
	my $alen = length('auto');
	splice(@$args, 1, 2, ('auto', substr($first, $alen))) if
	    index($first, 'auto') == 0 && length($first) > $alen;
    }
    $self->SUPER::run($args);
}

if (__FILE__ eq  $0) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc, $NAME);
    # require_relative '../mock'
    # dbgr, cmd = MockDebugger::setup
    $cmd->run([$NAME])
}

1;
