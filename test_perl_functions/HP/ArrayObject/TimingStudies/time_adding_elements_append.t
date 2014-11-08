#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::ArrayObject');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }

#=============================================================================
# First time object creation takes biggest hit within a perl script...
# Perl does caching on the backend, so we want to remove the initial startup
# costs of the first object creation of this type.
#=============================================================================
&RemoveObjectCreationBias( &creation_via_new() );

my @number_runs     = (1000);
my @number_elements = (1, 10, 100, 500, 1000, 5000, 10000, 100000);
my @types           = qw( integer string c__HP::ArrayObject__ );

print STDERR "\n\n================================================================\n";

for $t ( @types ) {
  for $nel ( @number_elements ) {
    for $rid ( @number_runs ) {
	  my @entries = ();
	  
	  @entries = &MakeNumbers(0,$nel,$nel,0) if ( $t eq 'integer' );
	  @entries = &MakeFileNames($nel, 200) if ( $t eq 'string' );
	  @entries = map { &create_object($t); } ( 0 .. $nel ) if ( $t =~ m/^c__/ );
	  
      my $result = &time_addelements($rid, \@entries);
      &diag("\nComparison Report { runs = $rid | #elem = $nel | type = $t } [ ". $result->{'average'}->{'prefix'} ."s ] :: ". sprintf('%0.5f', $result->{'average'}->{'converted'}) ."\n\n");
	}
  }
}

print STDERR "================================================================\n\n";

# ======================================
# Closure objects
# ======================================
sub creation_via_new()
{
  return sub { my $obj = HP::ArrayObject->new(); };
}

sub addition($)
{
  my $entries_2_add = shift;
  return sub {
              my $obj = HP::ArrayObject->new();
			  $obj->add_elements( {'entries' => $entries_2_add } );
			 };
}

sub time_addelements
{
  if ( scalar(@_) < 1 or $_[0] < 0 ) {
    &diag("\n----> No report done for HP::ArrayObject.\n");
	return 0;
  }
  
  my $closure = &addition($_[1]);
  return &RunTrials( $closure, $_[0] );
}