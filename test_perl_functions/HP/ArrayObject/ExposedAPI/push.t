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

&debug_obj($arrobj1);