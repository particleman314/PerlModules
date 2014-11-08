#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }
  
my $setobj  = &create_object('c__HP::Array::QueueSet__');
my $nameobj = &create_object('c__HP::Array::QueueSet__');

my $otherobj = &create_object('c__HP::Array::QueueSet__');
$otherobj->sort_method(ASCENDING_SORT);

my $num_elements = 10;
my $num_selector = 10;

my @object_types = ( 'HP::Array::Set', 'HP::Array::Queue', 'HP::Array::QueueSet',
                     'HP::Array::Stack', 'HP::ArrayObject', 'HP::Array::PriorityQueue' );

my $counter = scalar(@object_types);

# Select a random number of numbers
# =================================
my @random_selector              = &MakeNumbers(1,$counter + 1,$num_selector,0);
my @number_elements_per_selector = &MakeNumbers(1,$num_elements,$num_selector,0);

$otherobj->add_elements({'entries' => \@random_selector});
diag("Number of distinct Types [ @random_selector ] = ". $otherobj->number_elements());

for ( my $loopouter = 0; $loopouter < scalar(@random_selector); ++$loopouter ) {
  my $objtype = $object_types[$random_selector[$loopouter] - 1];
  $nameobj->push_item("$objtype");
  
  my $tempobj = &create_object('c__'.$objtype.'__');
  if ( defined($tempobj) ) {
    diag("Creating $number_elements_per_selector[$loopouter] of object << $objtype >>");
    for ( my $loopinner = 0; $loopinner < $number_elements_per_selector[$loopouter]; ++$loopinner ) {
	  $clonedobj = &clone_item($tempobj);
	  $setobj->push_item($clonedobj);
	}
  }
}

diag($setobj->number_elements() . " " . $nameobj->number_elements() . " " . $otherobj->number_elements());
is ( $nameobj->number_elements() == $otherobj->number_elements(), 1 );
is ( $setobj->number_elements() == $otherobj->number_elements(), 1 );

&debug_obj( $nameobj );
&debug_obj( $setobj );
