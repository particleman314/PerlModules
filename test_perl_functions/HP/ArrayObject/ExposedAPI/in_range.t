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
  
my @input1 = ( 1 .. 5, 7 .. 10 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );
$arrobj1->add_elements( {'entries' => [6], 'location' => PREPEND});

my $result = $arrobj1->in_range();
is ( $result eq FALSE, 1 );

$result = $arrobj1->in_range(-9);
is ( $result eq FALSE, 1 );

$result = $arrobj1->in_range(scalar(@input1) + 56);
is ( $result eq FALSE, 1 );

$result = $arrobj1->in_range(3);
is ( $result eq TRUE, 1 );

&debug_obj( $arrobj1 );