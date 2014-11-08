#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::Capsule::SharedFlowMap__');
is ( defined($obj), 1 );

$obj->update_map('abc/def', 'my_usecase1');
$obj->update_map('abc/def', 'my_usecase2');
$obj->update_map('abc/def', 'my_usecase3');

#This extra duplicate should NOT be added and a warning should be emitted
$obj->update_map('abc/def', 'my_usecase3');

is ( $obj->number_of_available_builds('abc/def') eq 3, 1 );

$obj->update_map('uvw/xyz', 'other_usecase1');
$obj->update_map('uvw/xyz', 'other_usecase2');

is ( $obj->number_of_available_builds('uvw/xyz') eq 2, 1 );

$obj->prepare_usage();

&debug_obj($obj);