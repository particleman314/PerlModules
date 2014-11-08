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

&debug_obj( $pqobj1 );

my $result = $pqobj1->next();
is ( defined($result), 1 );
is ( $result == 1, 1 );

$result = $pqobj1->next(1);
is ( defined($result), 1 );
is ( $result == 2, 1 );

$result = $pqobj1->next(4);
is ( defined($result), 1 );
is ( scalar(@{$result}) == 4, 1 );

&debug_obj( $result );
&debug_obj( $pqobj1 );

$result = $pqobj1->get_priorities();
is ( scalar(@{$result}) == 1, 1 );
is ( $result->[0] == 2, 1 );

$result = $pqobj1->next(4);
is ( defined($result), 1 );
is ( scalar(@{$result}) == 3, 1 );

&debug_obj( $pqobj1 );