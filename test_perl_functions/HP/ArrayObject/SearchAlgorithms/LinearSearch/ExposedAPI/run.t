#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
  }
  
my $arrobj = &create_object('c__HP::ArrayObject__');
my $setobj = &create_object('c__HP::Array::Set__');
$setobj->sort_method(ASCENDING_SORT);

my @elements = qw(2 4 6 8 0 1 3 5 7 9);
my $item2find = 7;

$arrobj->add_elements({'entries' => \@elements});
$setobj->add_elements({'entries' => \@elements});

my $srchobj = &create_object('c__HP::Array::SearchAlgorithms::LinearSearch__');
is ( defined($srchobj), 1 );

my $result = $srchobj->run();
is ( $result eq NOT_FOUND, 1 );

$srchobj->item($item2find);
$result = $srchobj->run();
is ( $result eq NOT_FOUND, 1 );

$srchobj->clear();

$srchobj->arrayobject($arrobj->clone());
$result = $srchobj->run();
is ( $result eq NOT_FOUND, 1 );

$srchobj->clear();

$srchobj->arrayobject($arrobj->clone());
$srchobj->item($item2find);

$result = $srchobj->run();
diag("Found item <$item2find> at location $result");
is ( $result eq 8, 1 );

&debug_obj($srchobj);

$srchobj->clear();
$srchobj->arrayobject($setobj->clone());
$srchobj->item($item2find);

$result = $srchobj->run();
diag("Found item <$item2find> at location $result");
is ( $result eq 7, 1 );

&debug_obj($srchobj);