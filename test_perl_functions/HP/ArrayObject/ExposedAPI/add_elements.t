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

my @contents = $arrobj1->get_elements();

is ($contents[0] == 6, 1);
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 10, 1);
$arrobj1->add_elements([10, 50, 100], FALSE, APPEND, TRUE); # entries array ref, multi-item format, location, skip-checks

@contents = $arrobj1->get_elements();
is ( $contents[-1] == 100, 1 );

&debug_obj( $arrobj1 );