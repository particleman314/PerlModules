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

my $pqobj1 = &create_object('c__HP::Array::PriorityQueue__');
$pqobj1->push_item([1, 5], [ \@bucket1, \@bucket2 ]);

my $result = $pqobj1->get_queue(1);
is ( defined($result), 1 );
my $result2 = $pqobj1->number_elements(1);

is ( $result2 == 1, 1 );

&debug_obj( $pqobj1 );
