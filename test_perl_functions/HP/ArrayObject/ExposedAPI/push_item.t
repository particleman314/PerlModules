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

my @input1 = ( 1 .. 5 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );

my $contains = $arrobj1->contains(1);
is ( $contains eq TRUE, 1 );

my $count = $arrobj1->number_elements();
is ( $count == 5, 1);

$arrobj1->push_item(6, PREPEND);
$count = $arrobj1->number_elements();
my @elements = $arrobj1->get_elements();

is ( $count == 6, 1 );
is ( $elements[0] == 6, 1 );

$arrobj1->push_item(7, 5);
$count = $arrobj1->number_elements();
@elements = $arrobj1->get_elements();

is ( $count == 7, 1 );
is ( $elements[4] == 7, 1 );

&debug_obj($arrobj1);