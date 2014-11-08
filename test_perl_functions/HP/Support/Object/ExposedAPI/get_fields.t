#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object');
    use_ok('HP::Support::Object::Tools');
  }

my $result = &get_fields();
is ( scalar(@{$result}) == 0, 1 );

my $objtemplate = {};
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 0, 1 );
$result = &get_fields($obj);
is ( scalar(@{$result}) == 0, 1 );
&debug_obj($obj);

$objtemplate = { 'field1' => undef, 'field2' => undef };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 2, 1 );
$result = &get_fields($obj);
is ( scalar(@{$result}) == 2, 1 );
&debug_obj($obj);

$objtemplate = { 'field1' => [], 'field2' => undef };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 2, 1 );
$result = &get_fields($obj);
is ( scalar(@{$result}) == 2, 1 );
&debug_obj($obj);

$objtemplate = { 'field1' => [], 'field2' => [], 'field3' => {} };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 3, 1 );
$result = &get_fields($obj);
is ( scalar(@{$result}) == 3, 1 );
&debug_obj($obj);

$objtemplate = { 'field2' => [], 'field1' => 'c__HP::ArrayObject__' };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 2, 1 );
is ( &is_type($obj->{'field1'}, 'HP::ArrayObject') eq TRUE, 1 );
is ( $obj->{'field1'}->number_elements() == 0, 1 );
$result = &get_fields($obj);
is ( scalar(@{$result}) == 2, 1 );
&debug_obj($obj);
