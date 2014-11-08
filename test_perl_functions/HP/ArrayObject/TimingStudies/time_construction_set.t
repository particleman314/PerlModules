#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Array::Set');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }

#=============================================================================
# First time object creation takes biggest hit within a perl script...
# Perl does caching on the backend, so we want to remove the initial startup
# costs of the first object creation of this type.
#=============================================================================
&RemoveObjectCreationBias( &creation_via_new() );

my @number_runs = (10000);

print STDERR "\n\n================================================================\n";

for ( @number_runs ) {
  my $result_bare    = &time_construction_bare($_);
  my $result_dressed = &time_construction_dressed('c__HP::Array::Set__', $_);
  
  my $intro        = "Comparison Report { $_ runs } ::";
  my $bare_info    = "< Bare avg time >    = ". sprintf('%0.4f', $result_bare->{'average'}->{'converted'}) ." [ ". $result_bare->{'average'}->{'prefix'} ."s ]";
  my $dressed_info = "< Dressed avg time > = ". sprintf('%0.4f', $result_dressed->{'average'}->{'converted'}) ." [ ". $result_dressed->{'average'}->{'prefix'} ."s ]";
  my $pctdiff      = "< % Diff [ B->D ] >  = ". sprintf('%0.2f', 100 * ($result_dressed->{'average'}->{'converted'} - $result_bare->{'average'}->{'converted'})/$result_bare->{'average'}->{'converted'});
  &diag("\n$intro\n\t$bare_info\n\t$dressed_info\n\t$pctdiff\t\t{ Positive means faster }\n\n");
}

print STDERR "================================================================\n\n";

# ======================================
# Closure objects
# ======================================
sub creation_via_tool($)
{
  my $input_type = shift;
  return sub { my $obj = &create_object($input_type); };
}

sub creation_via_new()
{
  return sub { my $obj = HP::Array::Set->new(); };
}

sub time_construction_dressed
{
  if ( scalar(@_) < 1 or $_[1] < 0 ) {
    &diag("\n----> No report done for $_[0].\n");
	return 0;
  }

  my $closure = &creation_via_tool($_[0]);
  return &RunTrials( $closure, $_[1] );
}

sub time_construction_bare
{
  if ( scalar(@_) < 0 or $_[0] < 0 ) {
    &diag("\n----> No report done for HP::Array::Queue.\n");
	return 0;
  }
  
  my $closure = &creation_via_new();
  return &RunTrials( $closure, $_[0] );
}