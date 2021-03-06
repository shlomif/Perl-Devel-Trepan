# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockb@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use lib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Files;
use Cwd 'abs_path';

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::DB::LineCache;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our @DEFAULT_FILE_ARGS = qw(size mtime sha1);
our $DEFAULT_FILE_ARGS = join(' ', @DEFAULT_FILE_ARGS);

## FIXME: do automatically.
our $CMD = "info files";

our $MAX_ARGS   = 8;  # Need at most this many - undef -> unlimited.
our $HELP = <<"HELP";
${CMD} [{FILENAME|.|*} [all|ctime|brkpts|mtime|sha1|size|stat]]

Show information about the current file. If no filename is given and
the program is running, then the current file associated with the
current stack entry is used. Giving . has the same effect. 

Given * gives a list of all files we know about.

Sub options which can be shown about a file are:

brkpts -- Line numbers where there are statement boundaries. 
          These lines can be used in breakpoint commands.
ctime  -- File creation time
iseq   -- Instruction sequences from this file.
mtime  -- File modification time
sha1   -- A SHA1 hash of the source text. This may be useful in comparing
          source code.
size   -- The number of lines in the file.
stat   -- File.stat information

all    -- All of the above information.

If no sub-options are given, \"$DEFAULT_FILE_ARGS\" are assumed.

Examples:

${CMD}    # Show \"${DEFAULT_FILE_ARGS}\" information about current file
${CMD} .  # same as above
${CMD} brkpts      # show the number of lines in the current file
${CMD} brkpts size # same as above but also list breakpoint line numbers
${CMD} *  # Give a list of files we know about
HELP

our $SHORT_HELP = 'Show information about the current loaded file(s)';
our $MIN_ABBREV = length('fi');

sub file_list($) 
{
    my $self = shift;
    sort((DB::LineCache::cached_files(),
	  keys(%DB::LineCache::file2file_remap)));
}

sub complete($$)
{
    my ($self, $prefix) = @_;
    my @completions = ('.', $self->file_list());
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

sub run($$) 
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args; shift @args; shift @args;
    push(@args, '.') if scalar @args == 0;
    if ($args[0] eq '*') {
	$proc->section('Cached files:');
	my @primary = DB::LineCache::cached_files();
	@primary = sort @primary;
	$proc->msg($self->{cmd}->columnize_commands(\@primary));
	return;
    }
    my $filename = shift @args;
    if ($filename eq '.') {
        my $frame_file = $proc->{frame}{file};
	$filename = DB::LineCache::map_file($frame_file) ||
	    abs_path($frame_file);
    }
    @args = @DEFAULT_FILE_ARGS if 0 == scalar @args;

    my $m = $filename;
    my $canonic_name = $proc->canonic_file($filename);
    $canonic_name = DB::LineCache::map_file($canonic_name) || $canonic_name;
    if (DB::LineCache::is_cached($canonic_name)) {
	$m .= " is cached in debugger";
	if ($canonic_name ne $filename) {
	    $m .= (" as:\n  " + $canonic_name);
	}
	$m .= '.';
	$proc->msg($m);
    # } elsif (!(matches = find_scripts(filename)).empty?) {
    # 	if (matches.size > 1) {
    # 	    $self->msg("Multiple files found:");
    # 	    matches.sort.each { |match_file| msg "\t%s" % match_file }
    # 	    return;
    # 	} else {
    # 	    $self->msg('File "%s" just now cached.' % filename);
    # 	    LineCache::cache(matches[0]);
    # 	    LineCache::remap_file(filename, matches[0]);
    # 	    canonic_name = matches[0];
    # 	}
    } else {
      my @matches = ();
      for my $try ($self->file_list()) {
	  push @matches, $try unless -1 == rindex($try, $filename);
      }
      if (scalar(@matches) > 1) {
      	  $proc->msg("Multiple files found ending filename string:");
	  for my $match_file (@matches) {
	      $proc->msg("\t$match_file");
	  }
	  return
      } elsif (1 == scalar(@matches)) {
      	  $canonic_name = DB::LineCache::map_file($matches[0]);
      	  $m .= " matched debugger cache file:\n\t"  . $canonic_name;
      	  $proc->msg($m);
      	 } else {
      	     $proc->msg($m . ' is not cached in debugger.');
      	     return;
      	 }
    }
    my %seen;
    for my $arg (@args) { 
	my $processed_arg = 0;
	my $arg = lc($arg);

	if ($arg eq 'all' || $arg eq 'size') {
	    unless ($seen{size}) {
		my $max_line = DB::LineCache::size($canonic_name);
		$proc->msg("File has $max_line lines.") if defined $max_line;
	    }
	    $processed_arg = $seen{size} = 1;
	}

	if ($arg eq 'all' || $arg eq 'sha1') {
	    unless ($seen{sha1}) {
		my $sha1 = DB::LineCache::sha1($canonic_name);
		$proc->msg("SHA1: ${sha1}");
	    }
	    $processed_arg = $seen{sha1} = 1;
	}

	if ($arg eq 'all' || $arg eq 'brkpts') {
	    unless ($seen{brkpts}) {
		$proc->msg("Possible breakpoint line numbers:");
		my @lines = DB::LineCache::trace_line_numbers($canonic_name);
		my $fmt_lines = $self->{cmd}->columnize_numbers(\@lines);
		$proc->msg($fmt_lines);
	    }
	    $processed_arg = $seen{brkpts} = 1;
	}

	if ($arg eq 'all' || $arg eq 'ctime') {
	    unless ($seen{ctime}) {
		my $stat = DB::LineCache::stat($canonic_name);
		if (defined $stat) {
		    my $ctime = DB::LineCache::stat($canonic_name)->ctime;
		    $ctime = localtime($ctime);
		    $proc->msg("Creation time:\t$ctime");
		}
	    }
	    $processed_arg = $seen{ctime} = 1;
	}
      
	if ($arg eq 'all' || $arg eq 'mtime') {
	    unless ($seen{mtime}) {
		my $stat = DB::LineCache::stat($canonic_name);
		if (defined($stat)) {
		    my $mtime = localtime($stat->mtime);
		    $proc->msg("Modify time:\t$mtime");
		}
	    }
	    $processed_arg = $seen{mtime} = 1;
	}
      
	# if ($arg eq 'all' || $arg eq 'stat') {
	#     unless ($seen{stat}) {
	# 	require Enbugger; Enbugger->stop;
	# 	my $stat = DB::LineCache::stat($canonic_name);
	# 	my $msg = sprintf "File attributes:\t%s", join(', ', @$stat);
	# 	$proc->msg($msg);
	#     }
	#     $processed_arg = $seen{stat} = 1;
	# }
      
	unless ($processed_arg) {
	    $proc->errmsg("I don't understand sub-option \"$arg\"");
	}
    }
}

unless (caller) {
    require Devel::Trepan;
    require Devel::Trepan::DB::LineCache;
    DB::LineCache::cache_file(__FILE__);
    print join(', ', file_list('bogus')), "\n";
    # Demo it.
    # require_relative '../../mock'
    # my($dbgr, $parent_cmd) = MockDebugger::setup('show');
    # $cmd = __PACKAGE__->new(parent_cmd);
    # $cmd->run(@$cmd->prefix);
}

# Suppress a "used-once" warning;
$HELP || scalar @SUBCMD_VARS;
