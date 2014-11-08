#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
  }

my $obj = &create_object();
is ( (not defined($obj)) == 1, 1 );

my $objtemplate = {};
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 0, 1 );
&debug_obj($obj);

$objtemplate = { 'field1' => undef, 'field2' => undef };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 2, 1 );
&debug_obj($obj);

$objtemplate = { 'field1' => [], 'field2' => undef };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 2, 1 );
&debug_obj($obj);

$objtemplate = { 'field1' => [], 'field2' => undef, 'field3' => {} };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 3, 1 );
&debug_obj($obj);

$objtemplate = { 'field1' => undef, 'array1' => 'c__HP::ArrayObject__' };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 2, 1 );
is ( &is_type($obj->{'array1'}, 'HP::ArrayObject') eq TRUE, 1 );
is ( $obj->{'array1'}->number_elements() == 0, 1 );
&debug_obj($obj);

$objtemplate = { 'field1' => undef, 'array1' => 'c__HP::ArrayObject__', 'deeparray1' => '[] c__HP::ArrayObject__ 1' };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 3, 1 );
is ( &is_type($obj->{'array1'}, 'HP::ArrayObject') eq TRUE, 1 );
is ( $obj->{'array1'}->number_elements() == 0, 1 );
&debug_obj($obj);
