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
my $result = $arrobj1->get_element_at_front();
is ( (not defined($result)), 1 );

$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );

$result = $arrobj1->get_element_at_front();
is ( defined($result), 1 );
is ( $result == 1, 1 );

$arrobj1->add_elements( {'entries' => [6], 'location' => PREPEND});
$result = $arrobj1->get_element_at_front();
is ( defined($result), 1 );
is ( $result == 6, 1 );

&debug_obj( $arrobj1 );