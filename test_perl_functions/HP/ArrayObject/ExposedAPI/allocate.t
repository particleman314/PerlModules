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

my $arrobj1 = &create_object('c__HP::ArrayObject__');
is ( $arrobj1->number_elements() == 0, 1 );

my $result = $arrobj1->allocate();
is ( $arrobj1->number_elements() == 0, 1 );
is ( $result eq FALSE, 1 );

$result = $arrobj1->allocate('my size');
is ( $arrobj1->number_elements() == 0, 1 );
is ( $result eq FALSE, 1 );

$result = $arrobj1->allocate(0);
is ( $arrobj1->number_elements() == 0, 1 );
is ( $result eq FALSE, 1 );

$result = $arrobj1->allocate(-10);
is ( $arrobj1->number_elements() == 0, 1 );
is ( $result eq FALSE, 1 );

$result = $arrobj1->allocate(10);
is ( $arrobj1->number_elements() == 0, 1 );
is ( $result eq TRUE, 1 );

&debug_obj( $arrobj1 );