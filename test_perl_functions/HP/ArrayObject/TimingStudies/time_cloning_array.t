#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::ArrayObject');
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

my $clonable_object = &create_object('c__HP::ArrayObject__');

my @number_runs = (1, 10, 25, 50, 100, 500, 1000, 2500, 5000, 10000);

print STDERR "\n\n================================================================\n";

for ( @number_runs ) {
  my $result_construct = &time_construction($_);
  my $result_clone     = &time_clone($clonable_object, $_);
  
  my $intro           = "Comparison Report { $_ runs } ::";
  my $construct_info  = "< Construct avg time >          = ". sprintf('%0.4f', $result_construct->{'average'}->{'converted'}) ." [ ". $result_construct->{'average'}->{'prefix'} ."s ]";
  my $clone_info      = "< Clone avg time >              = ". sprintf('%0.4f', $result_clone->{'average'}->{'converted'}) ." [ ". $result_clone->{'average'}->{'prefix'} ."s ]";
  my $pctdiff         = "< % Diff [ Clone->Construct ] > = ". sprintf('%0.2f', 100 * ($result_construct->{'average'}->{'converted'} - $result_clone->{'average'}->{'converted'})/$result_clone->{'average'}->{'converted'});
  &diag("\n$intro\n\t$construct_info\n\t$clone_info\n\t$pctdiff\t\t{ Positive means faster }\n\n");
}

print STDERR "================================================================\n\n";

# ======================================
# Closure objects
# ======================================
sub creation_via_clone($)
{
  my $input_type = shift;
  return sub { $input_type->__turn_on_cloning(); my $obj = $input_type->clone(); };
}

sub creation_via_new()
{
  return sub { my $obj = HP::ArrayObject->new( {&ARRAY_SKIP_CLONE_OPTION => TRUE} ); };
}

sub time_clone
{
  if ( scalar(@_) < 1 or $_[1] < 0 ) {
    &diag("\n----> No report done for $_[0].\n");
	return 0;
  }

  my $closure = &creation_via_clone($_[0]);
  return &RunTrials( $closure, $_[1] );
}

sub time_construction
{
  if ( scalar(@_) < 0 or $_[0] < 0 ) {
    &diag("\n----> No report done for HP::ArrayObject.\n");
	return 0;
  }
  
  my $closure = &creation_via_new();
  return &RunTrials( $closure, $_[0] );
}