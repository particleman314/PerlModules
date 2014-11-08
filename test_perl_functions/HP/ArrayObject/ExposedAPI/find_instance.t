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
  }

my @input2 = qw( A B C D E F A A D A B );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
$arrobj1->add_elements( {'entries' => \@input2, 'location' => APPEND});
&debug_obj( $arrobj1 );

my $matching_idx = $arrobj1->find_instance('A');

&debug_obj( $matching_idx );

my $result = $arrobj1->delete_elements_by_index($matching_idx);
is ( $result eq TRUE, 1 );
is ( $arrobj1->contains('A') eq TRUE, 1 );

$matching_idx = $arrobj1->find_instance('F');

&debug_obj( $matching_idx );

$result = $arrobj1->delete_elements_by_index($matching_idx);
is ( $result eq TRUE, 1 );
is ( $arrobj1->contains('F') eq FALSE, 1 );

&debug_obj($arrobj1);