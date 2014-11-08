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
my @contents = $qobj1->get_elements();
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 9, 1);

$qobj1->push_item();
@contents = $qobj1->get_elements();
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 9, 1);

$qobj1->push_item(9);
@contents = $qobj1->get_elements();
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 9, 1);

$qobj1->push_item('Zap');
@contents = $qobj1->get_elements();
is ($contents[-1] eq 'Zap', 1);
is (scalar(@contents) == 10, 1);

$qobj1->push_item({'data' => 'Zap2', 'location' => APPEND});
@contents = $qobj1->get_elements();
is ($contents[-1] eq 'Zap2', 1);
is (scalar(@contents) == 11, 1);

&debug_obj( $qobj1 );