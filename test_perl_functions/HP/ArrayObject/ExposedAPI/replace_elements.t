#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
  }
  
my @input1 = ( 1 .. 5, 7 .. 10 );
my @replace = ( 11 .. 20 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );
$arrobj1->add_elements( {'entries' => [6], 'location' => PREPEND});

my @contents = $arrobj1->get_elements();

is ( $contents[0] == 6, 1 );
is ( $contents[-1] == 10, 1 );
is ( scalar(@contents) == 10, 1 );

$arrobj1->replace_elements(\@replace);

@contents = $arrobj1->get_elements();
is ( $arrobj1->number_elements() == 10, 1 );
is ( $contents[-1] == 20, 1 );
is ( $contents[0] == 11, 1 );

&debug_obj( $arrobj1 );