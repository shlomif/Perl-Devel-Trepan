# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use strict;
use warnings;
use Exporter;


package Devel::Trepan::Complete;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(complete_token complete_token_with_next 
             next_token
             complete_token_filtered_with_next);

# Return an Array of String found from Array of String
# +complete_ary+ which start out with String +prefix+.
sub complete_token($$)
{
    my ($complete_ary, $prefix) = @_;
    my @result = ();
    for my $cmd (@$complete_ary) { 
	push @result, $cmd if 0 == index($cmd, $prefix);
    }
    sort @result;
}
    
sub complete_token_with_next($$;$) 
{
    my ($complete_hash, $prefix, $cmd_prefix) = @_;
    $cmd_prefix ='' if scalar(@_) < 3;
    my $cmd_prefix_len = length($cmd_prefix);
    my @result = ();
    while (my ($cmd_name, $cmd_obj) = each %{$complete_hash}) {
	if  (0 == index($cmd_name, $cmd_prefix . $prefix)) {
	    push @result, [substr($cmd_name, $cmd_prefix_len), $cmd_obj] 
	}
    }
    sort {$a->[0] cmp $b->[0]} @result;
}
    
# Find all starting matches in Hash +aliases+ that start with +prefix+,
# but filter out any matches already in +expanded+.
sub complete_token_filtered($$$)
{
    my ($aliases, $prefix, $expanded) = @_;
    my @complete_ary = keys %{$aliases};
    my @result = ();
    for my $cmd (@complete_ary) { 
	push @result, $cmd if 
	    0 == index($cmd, $prefix) && !exists $expanded->{$aliases->{$cmd}};
    }
    sort @result;
}

# Find all starting matches in Hash +aliases+ that start with +prefix+,
# but filter out any matches already in +expanded+.
sub complete_token_filtered_with_next($$$$)
{
    my ($aliases, $prefix, $expanded, $commands) = @_;
    # require Enbugger; Enbugger->stop;
    my @complete_ary = keys %{$aliases};
    my %expanded = %{$expanded};
    my @result = ();
    for my $cmd (@complete_ary) {
	if (0 == index($cmd, $prefix) && !exists $expanded{$aliases->{$cmd}}) {
	    push @result, [$cmd, $commands->{$aliases->{$cmd}}];
	}
    }
    @result;
  }

# Find the next token in str string from start_pos. We return
# the token and the next blank position after the token or 
# length($str) if this is the last token. Tokens are delimited by
# white space.
sub next_token($$)
{
    my ($str, $start_pos) = @_;
    my $look_at = substr($str, $start_pos);
    my $strlen = length($look_at);
    return (1, '') if 0 == $strlen;
    my $next_nonblank_pos = $start_pos;
    my $next_blank_pos;
    if ($look_at =~ /^(\s*)(\S+)\s*/) {
	$next_nonblank_pos += length($1);
	$next_blank_pos = $next_nonblank_pos+length($2);
    } elsif ($look_at =~ /^(\s+)$/) {
	return ($start_pos + length($1), '');
    } elsif ($look_at =~/^(\S+)\s*/) {
	$next_blank_pos = $next_nonblank_pos + length($1);
    } else {
	die "Something is wrong in next_token";
    }
    my $token_size = $next_blank_pos - $next_nonblank_pos;
    return ($next_blank_pos, substr($str, $next_nonblank_pos, $token_size));
}

unless (caller) {
    my $hash_ref = {'ab' => 1, 'aac' => 2, 'aa' => 3, 'b' => 4};
    my @cmds = keys %{$hash_ref};
    printf("complete_token(@cmds, 'a') => %s\n",
	   join(', ', complete_token(\@cmds, 'a')));
    printf("complete_token(@cmds, 'b') => %s\n",
	   join(', ', complete_token(\@cmds, 'b')));
    printf("complete_token(@cmds, 'c') => %s\n",
	   join(', ', complete_token(\@cmds, 'c')));
    my @ary = complete_token_with_next($hash_ref, 'a');
    my @ary_str = map "($_->[0], $_->[1])", @ary;
    printf("complete_token_with_next(\$hash_ref, 'a') => %s\n",
	   join(', ', @ary_str));
    print   "0         1        \n";
    print   "0123456789012345678\n";
    my $x = '  now is  the  time';
    print "$x\n";
    for my $pos (0, 2, 5, 6, 8, 9, 13, 18, 19) { 
	my @ary = next_token($x, $pos);
	printf "next_token($pos) = %d, '%s'\n", $ary[0], $ary[1];
    }
}

1;
