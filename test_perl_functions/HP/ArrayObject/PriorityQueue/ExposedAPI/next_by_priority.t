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
my @bucket2 = ( 7 .. 10 );

my $pqobj1 = &create_object('c__HP::Array::PriorityQueue__');
$pqobj1->add_elements([1], \@bucket1);
$pqobj1->add_elements([2], \@bucket2);

my $result = $pqobj1->next_by_priority();
is ( defined($result), 1 );
is ( $result == 1, 1 );

$result = $pqobj1->next_by_priority(1);
is ( defined($result), 1 );
is ( $result == 2, 1 );

$result = $pqobj1->next_by_priority(2);
is ( defined($result), 1 );
is ( $result == 7, 1 );

$result = $pqobj1->next_by_priority(1,4);
is ( defined($result), 1 );
is ( scalar(@{$result}) == 3, 1 );

&debug_obj( $pqobj1 );
