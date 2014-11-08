#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }
  
my @input1 = ( 1 .. 5, 7 .. 10 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
is ( $arrobj1->number_elements() == 0, 1 );

$arrobj1->__prepare_object();
is ( $arrobj1->number_elements() == 0, 1 );

my $newobj = $arrobj1->__prepare_object(\@input1);
is ( $newobj->number_elements() == scalar(@input1), 1 );

my $newobj2 = $arrobj1->__prepare_object(1);
is ( $newobj2->number_elements() == 1, 1 );
is ( $newobj2->get_element(0) == 1, 1 );

&debug_obj( $newobj );
&debug_obj( $newobj2 );
