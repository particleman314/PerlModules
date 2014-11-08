#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
  }
  
my @bucket1 = ( 1 .. 5, 10 );

my $pqobj1 = &create_object('c__HP::Array::PriorityQueue__');
$pqobj1->push(1, \@bucket1);

my $pqobj2 = &create_object('c__HP::Array::PriorityQueue__');
$pqobj2->__set_queue_type('HP::Array::Set', DESCENDING_SORT);
$pqobj2->push(1, \@bucket1);

is ( $pqobj2->get_queue(1)->get_element_at_back() == 1, 1 );

&debug_obj( $pqobj1 );
&debug_obj( $pqobj2 );

