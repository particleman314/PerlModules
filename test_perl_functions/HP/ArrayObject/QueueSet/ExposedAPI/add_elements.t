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

my $qobj1 = &create_object('c__HP::Array::QueueSet__');
$qobj1->add_elements( {'entries' => \@input1} );
@contents = $qobj1->get_elements();
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 9, 1);

$qobj1->add_elements( {'entries' => [6]});
@contents = $qobj1->get_elements();
is ($contents[-1] == 6, 1);
is (scalar(@contents) == 10, 1);

$qobj1->add_elements( {'entries' => [3]});
@contents = $qobj1->get_elements();
is ($contents[-1] == 6, 1);
is (scalar(@contents) == 10, 1);

$qobj1->add_elements( {'entries' => [44]});
@contents = $qobj1->get_elements();
is ($contents[-1] == 44, 1);
is (scalar(@contents) == 11, 1);

&debug_obj( $qobj1 );