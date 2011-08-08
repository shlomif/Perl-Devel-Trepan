# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use lib '../../../..';

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Next;

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;
use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME}[+|-] [count]

Step one statement ignoring steps into function calls at this level.
Sometimes this is called 'step over'.

With an integer argument, perform '${NAME}' that many times. However if
an exception occurs at this level, or we 'return' or 'yield' or the
thread changes, we stop regardless of count.

A suffix of '+' on the command or an alias to the command forces to
move to another line, while a suffix of '-' does the opposite and
disables the requiring a move to a new line. If no suffix is given,
the debugger setting 'different' determines this behavior.

If no suffix is given, the debugger setting 'different'
determines this behavior.

Examples: 
  ${NAME}
HELP

use constant ALIASES    => qw(n next+ next- n+ n-);
use constant CATEGORY   => 'running';
use constant SHORT_HELP => 'Step program without entering called functions';
local $MAX_ARGS     = 1;   # Need at most this many. FIXME: will be eventually 2
local $NEED_RUNNING = 1;


#  include Trepan::Condition

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;

    $self->{proc}->{leave_cmd_loop} = 1;
    no warnings;
    $self->{dbgr}->next();
}

if (__FILE__ eq $0) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
