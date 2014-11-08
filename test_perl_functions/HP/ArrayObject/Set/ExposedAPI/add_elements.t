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
  
my @input1 = ( 1 .. 5, 7 .. 10 );

my $setobj1 = &create_object('c__HP::Array::Set__');
$setobj1->sort_method(ASCENDING_SORT);
$setobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );
@contents = $setobj1->get_elements();
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 9, 1);

$setobj1->add_elements( {'entries' => [6], 'location' => PREPEND});
@contents = $setobj1->get_elements();
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 10, 1);

$setobj1->add_elements( {'entries' => [3], 'location' => PREPEND});
@contents = $setobj1->get_elements();
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 10, 1);

$setobj1->add_elements( {'entries' => [44], 'location' => PREPEND});
@contents = $setobj1->get_elements();
is ($contents[-1] == 44, 1);
is (scalar(@contents) == 11, 1);

&debug_obj( $setobj1 );
