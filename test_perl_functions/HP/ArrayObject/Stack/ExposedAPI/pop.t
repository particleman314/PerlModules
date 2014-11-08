#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }

my @input1 = ( 1 .. 7 );

my $arrobj1 = &create_object('c__HP::Array::Stack__');
$arrobj1->add_elements( {'entries' => \@input1} );

my $contains = $arrobj1->contains(1);
is ( $contains eq TRUE, 1 );

my $count = $arrobj1->number_elements();
is ( $count == 7, 1);

$arrobj1->push(6);
$count = $arrobj1->number_elements();
my @elements = $arrobj1->get_elements();

is ( $count == 8, 1 );
is ( $elements[7] == 6, 1 );

&debug_obj($arrobj1);

my $result = $arrobj1->pop();
$count = $arrobj1->number_elements();
@elements = $arrobj1->get_elements();

is ( $result == 6, 1 );
is ( $count == 7, 1 );
is ( $elements[6] == 7, 1 );

&debug_obj($arrobj1);

$result = $arrobj1->pop(4);
$count = $arrobj1->number_elements();
is ( ref($result) =~ m/^array/i, 1 );
is ( $count == 3, 1 );

&debug_obj($result);
&debug_obj($arrobj1);