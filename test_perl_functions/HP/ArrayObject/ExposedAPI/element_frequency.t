#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }

my @input1 = ( 1 .. 5, 7 .. 10, 1 .. 5 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );

my $contains = $arrobj1->contains(1);
my $matches = $arrobj1->find_all_instances('1');
is ( $contains eq TRUE, 1 );
is ( scalar(@{$matches}) == 2, 1 );

my $count = $arrobj1->element_frequency(1);
is ( $count == 2, 1);

$count = $arrobj1->element_frequency(10);
is ( $count == 1, 1 );

$count = $arrobj1->element_frequency(44);
is ( $count == 0, 1 );

&debug_obj($arrobj1);