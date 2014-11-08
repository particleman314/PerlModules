#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
  }
  
my $obj = &create_object('c__HP::Capsule::SharedFlowMap__');
is ( defined($obj), 1 );

$obj->update_map('abc/def', 'my_usecase1');
$obj->update_map('abc/def', 'my_usecase2');
$obj->update_map('abc/def', 'my_usecase3');
$obj->update_map('uvw/xyz', 'other_usecase1');
$obj->update_map('uvw/xyz', 'other_usecase2');

$obj->prepare_usage();
my $result = $obj->available_for_building('my_usecase1');
is ( $result eq TRUE, 1 );

is ( $obj->number_of_available_builds('abc/def') eq 0, 1 );
is ( $obj->number_of_available_builds('uvw/xyz') eq 2, 1 );

$result = $obj->available_for_building('my_usecase3');
is ( $result ne TRUE, 1 );

$result = $obj->available_for_building();
is ( $result ne TRUE, 1 );

$result = $obj->available_for_building('');
is ( $result ne TRUE, 1 );

$result = $obj->available_for_building('blahblah');
is ( $result ne TRUE, 1 );

$result = $obj->available_for_building('other_usecase2');
is ( $result eq TRUE, 1 );
is ( $obj->number_of_available_builds('uvw/xyz') eq 0, 1 );

&debug_obj($obj);