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

my $result = $pqobj1->get_elements();

&debug_obj($result);

is ( defined($result), 1 );
is ( ref($result) =~ m/hash/i, 1 );

$result = $pqobj1->get_elements(1);
is ( defined($result), 1 );
is ( scalar(@{$result}) == 5, 1 );

$result = $pqobj1->get_elements(5);
is ( defined($result), 1 );
is ( ref($result) =~ m/^array/i, 1 );

&debug_obj( $pqobj1 );
