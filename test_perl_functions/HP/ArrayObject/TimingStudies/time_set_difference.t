#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('Time::HiRes');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }

my @seqcnt = ( 10, 25, 50, 75, 100, 250, 500, 1000, 2000, 5000, 10000 );

foreach my $max_items (@seqcnt) {
  diag("\n -------->>>>>>> Testing with maximum items set to :: $max_items\n");

  my @input1 = &MakeNumbers(0,$max_items,$max_items,0);
  my @input2 = &MakeNumbers(0,$max_items,$max_items,0);

  &test_set_difference(\@input1, \@input2);
  &test_array_difference(\@input1, \@input2);
}

sub test_array_difference($$) {
  my $setobj1 = &create_object('c__HP::Array::Set__');
  my $setobj2 = &create_object('c__HP::Array::Set__');

  $setobj1->sort_method(ASCENDING_SORT);
  $setobj2->sort_method(ASCENDING_SORT);

  $setobj1->add_elements( {'entries' => &clone_item($_[0]), 'location' => APPEND} );
  $setobj2->add_elements( {'entries' => &clone_item($_[1]), 'location' => APPEND} );

  my $array1 = &create_object('c__HP::ArrayObject__');
  my $array2 = &create_object('c__HP::ArrayObject__');

  my $unique_items1 = $setobj1->get_elements();
  my $unique_items2 = $setobj2->get_elements();
  
  $array1->add_elements( {'entries' => &clone_item($unique_items1), 'location' => APPEND} );
  $array2->add_elements( {'entries' => &clone_item($unique_items2), 'location' => APPEND} );

  diag("\nBeginning Array test with ".$array1->number_elements() . " & " .$array2->number_elements(). " elements in setA, setB\n");

  my ($delta_time, $result) = &test_difference($array1, $array2);

  diag("\nDelta Time : $delta_time seconds\n");
  diag("\nNumber of elements in difference : ". $result->number_elements(). "\n");

  is ( $result->number_elements() < $array1->number_elements(), 1 );
  &debug_obj( $result );
  &debug_obj( $array1 );
  &debug_obj( $array2 );
}

sub test_set_difference($$) {
  my $setobj1 = &create_object('c__HP::Array::Set__');
  my $setobj2 = &create_object('c__HP::Array::Set__');

  $setobj1->sort_method(ASCENDING_SORT);
  $setobj2->sort_method(ASCENDING_SORT);

  $setobj1->add_elements( {'entries' => &clone_item($_[0]), 'location' => APPEND} );
  $setobj2->add_elements( {'entries' => &clone_item($_[1]), 'location' => APPEND} );

  diag ("\nBeginning Set test with ".$setobj1->number_elements() . " & " .$setobj2->number_elements(). " elements in setA, setB\n" );

  my ($delta_time, $result) = &test_difference($setobj1, $setobj2);

  diag("\nDelta Time : $delta_time seconds\n");
  diag("\nNumber of elements in difference : ". $result->number_elements(). "\n");
  $result->sort_method(ASCENDING_SORT);
  $result->sort();

  is ( $result->number_elements() < $setobj1->number_elements(), 1 );
  &debug_obj( $result );
  &debug_obj( $setobj1 );
  &debug_obj( $setobj2 );
}

sub test_difference($$) {
  my $bgtime  = Time::HiRes::time();
  my $result  = &set_difference( $_[0], $_[1] );
  my $edtime  = Time::HiRes::time();
  
  my $difftime = $edtime - $bgtime;
  return ($difftime, $result);
}