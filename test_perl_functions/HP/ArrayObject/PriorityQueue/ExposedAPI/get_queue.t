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

my $result = $pqobj1->get_queue();
is ( ( not defined($result) ), 1 );

$result = $pqobj1->get_queue(-6);
is ( ( not defined($result) ), 1 );

$result = $pqobj1->get_queue('G');
is ( ( not defined($result) ), 1 );

$result = $pqobj1->get_queue(10);
is ( ( not defined($result) ), 1 );

$result = $pqobj1->get_queue(5);
is ( defined($result), 1 );

&debug_obj( $pqobj1 );
