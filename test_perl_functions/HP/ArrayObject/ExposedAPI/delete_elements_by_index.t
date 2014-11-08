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
  
my @input1 = ( 1 .. 5, 7 .. 10 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );
$arrobj1->add_elements( {'entries' => [6], 'location' => PREPEND});

my @contents = $arrobj1->get_elements();

is ($contents[0] == 6, 1);
is ($contents[-1] == 10, 1);
is (scalar(@contents) == 10, 1);

my @input2 = qw( A B C D E F A A D A B );
$arrobj1->add_elements( {'entries' => \@input2, 'location' => APPEND});
&debug_obj( $arrobj1 );

my $matchID = 'F';
my $matching_idx = $arrobj1->find_all_instances($matchID);

&debug_obj( $matching_idx );

my $result = $arrobj1->delete_elements_by_index($matching_idx);
is ( $result eq TRUE, 1 );
is ( $arrobj1->contains($matchID) eq FALSE, 1 );

$matchID = 'A';
$matching_idx = $arrobj1->find_all_instances($matchID);

$result = $arrobj1->delete_elements_by_index($matching_idx);
is ( $result eq TRUE, 1 );
is ( $arrobj1->contains($matchID) eq FALSE, 1 );

&debug_obj( $arrobj1 );