#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
    use_ok('HP::ArrayObject');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
	use_ok('HP::Utilities');
  }
  
my $arrobj1 = &create_object('c__HP::ArrayObject__');
my $internals = $arrobj1->data_types();
my $total_internals = $arrobj1->data_types(LOCAL);

my $match = &equal($internals, $total_internals);
is ( $match eq TRUE, 1 );

&debug_obj( $arrobj1 );