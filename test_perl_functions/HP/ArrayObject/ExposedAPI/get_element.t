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
$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );
$arrobj1->add_elements( {'entries' => [6], 'location' => PREPEND});

my $content = $arrobj1->get_element(0);

is ( $content == 6, 1 );

$content = $arrobj1->get_element();
is ( (not defined($content)), 1 );

$content = $arrobj1->get_element(-5);
is ( (not defined($content)), 1 );

$content = $arrobj1->get_element( scalar(@input1) + 10 );
is ( (not defined($content)), 1 );

$content = $arrobj1->get_element(5);
is ( $content == 5, 1 );

&debug_obj( $arrobj1 );