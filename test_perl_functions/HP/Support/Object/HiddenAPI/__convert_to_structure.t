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

my $details = {};
my $obj = &HP::Support::Object::Tools::__convert_to_structure($details);

is ( (not defined($obj)) == 1, 1 );

my $type = 'HP::ArrayObject';
$details = { 'class' => "$type" };
$obj = &HP::Support::Object::Tools::__convert_to_structure($details);

is ( defined($obj) == 1, 1 );
is ( &is_type($obj, "$type") eq TRUE, 1 );

&debug_obj($obj);

$type = 'HP::BaseObject';
$details = { 'class' => "$type" };
$obj = &HP::Support::Object::Tools::__convert_to_structure($details);

is ( defined($obj) == 1, 1 );
is ( &is_type($obj, "$type") eq TRUE, 1 );

&debug_obj($obj);
