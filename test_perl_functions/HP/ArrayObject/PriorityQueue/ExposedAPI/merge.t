#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
  }
  
my @bucket1 = ( 1 .. 5 );
my @bucket2 = ( 150 .. 160 );
my @bucket3 = ( 3 ..8);

my $pqobj1 = &create_object('c__HP::Array::PriorityQueue__');
my $pqobj2 = &create_object('c__HP::Array::PriorityQueue__');
my $pqobj3 = &create_object('c__HP::Array::PriorityQueue__');

$pqobj1->add_elements([1], \@bucket1);
$pqobj2->add_elements([3], \@bucket2);
$pqobj2->add_elements([1], \@bucket3);

$pqobj1->merge($pqobj2);
exit 1;

&debug_obj( $pqobj1 );
&debug_obj( $pqobj2 );
&debug_obj( $pqobj3 );
