#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
  }
  
my @bucket1 = ( 1 .. 10 );
my @bucket2 = ( 7 .. 10 );

my $pqobj1 = &create_object('c__HP::Array::PriorityQueue__');
$pqobj1->add_elements();

my $contents = $pqobj1->get_priorities();

is ( defined($contents), 1 );
is ( scalar(@{$contents}) == 0, 1);

$pqobj1->add_elements(\@bucket1);
$contents = $pqobj1->get_priorities();

is ( defined($contents), 1 );
is ( scalar(@{$contents}) == 1, 1);

$pqobj1->add_elements([2], \@bucket2);
$contents = $pqobj1->get_priorities();

is ( defined($contents), 1 );
is ( scalar(@{$contents}) == 2, 1);

&debug_obj( $pqobj1 );

my $pqobj2 = &create_object('c__HP::Array::PriorityQueue__');
$pqobj2->__set_queue_type('HP::Array::Set');

$pqobj2->add_elements(\@bucket1);
$contents = $pqobj2->get_priorities();

is ( defined($contents), 1 );
is ( scalar(@{$contents}) == 1, 1);

$pqobj1->add_elements([4], \@bucket2);
$contents = $pqobj1->get_priorities();

is ( defined($contents), 1 );
is ( scalar(@{$contents}) == 3, 1);

$pqobj2->add_elements(\@bucket2);
$contents = $pqobj2->get_priorities();

is ( defined($contents), 1 );
is ( scalar(@{$contents}) == 1, 1);

&debug_obj($pqobj2);
