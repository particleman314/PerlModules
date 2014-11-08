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
my @input2 = ( 100 .. 125 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
my $arrobj2 = &create_object('c__HP::ArrayObject__');
my $arrobj3 = &create_object('c__HP::ArrayObject__');

$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );
$arrobj2->add_elements( {'entries' => \@input2, 'location' => APPEND} );

is ( $arrobj1->number_elements() == scalar(@input1), 1 );
is ( $arrobj2->number_elements() == scalar(@input2), 1 );
is ( $arrobj3->number_elements() == 0, 1 );

$arrobj3->merge($arrobj1);
is ( $arrobj3->number_elements() == scalar(@input1), 1 );

$arrobj3->merge($arrobj2);
is ( $arrobj3->number_elements() == scalar(@input1) + scalar(@input2), 1 );

&debug_obj($arrobj3);