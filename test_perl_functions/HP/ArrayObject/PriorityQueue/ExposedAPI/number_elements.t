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
$pqobj1->push(1, \@bucket1);
$pqobj1->push([5], \@bucket2);
$pqobj1->push([ {'2' => &create_object('c__HP::Stream::IO__')},{'2' => '9'}, {'3' => 15} ]);

my $result = $pqobj1->number_elements();
is ( $result == scalar(@bucket1) + scalar(@bucket2) + 3, 1 );

$result = $pqobj1->number_elements(-9);
is ( $result == 0, 1 );

$result = $pqobj1->number_elements(10);
is ( $result == 0, 1 );

$result = $pqobj1->number_elements('Zap');
is ( $result == 0, 1 );

$result = $pqobj1->number_elements(5);
is ( $result == scalar(@bucket2), 1 );

&debug_obj( $pqobj1 );
