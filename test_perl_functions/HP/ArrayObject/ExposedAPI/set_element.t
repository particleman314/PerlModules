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

my @input1 = ( 1 .. 5, 6 .. 10 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
is ( $arrobj1->is_empty() eq TRUE, 1 );

$arrobj1->push(@input1);
is ( $arrobj1->number_elements() == scalar(@input1), 1 );

$arrobj1->set_element(undef, -5);
&debug_obj($arrobj1);
is ( $arrobj1->number_elements() == scalar(@input1), 1 );
is ( $arrobj1->contains(-5) eq FALSE, 1 );

$arrobj1->set_element(-7, 33);
&debug_obj($arrobj1);
is ( $arrobj1->number_elements() == scalar(@input1), 1 );
is ( $arrobj1->contains(33) eq FALSE, 1 );

$arrobj1->set_element(55, 11);
&debug_obj($arrobj1);
is ( $arrobj1->number_elements() == scalar(@input1), 1 );
is ( $arrobj1->contains(11) eq FALSE, 1 );

$arrobj1->set_element(5, 50);
is ( $arrobj1->number_elements() == scalar(@input1), 1 );
is ( $arrobj1->contains(50) eq TRUE, 1 );
is ( $arrobj1->get_element(5) == 50, 1 );

&debug_obj($arrobj1);