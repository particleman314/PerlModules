#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::Capsule::CapsuleDirective__');
is ( defined($obj), 1 );

my $oocobj = &create_object('c__HP::Capsule::OOCapsule__');
$oocobj->set_version('1.0.1');
my $ucobj  = &create_object('c__HP::Capsule::UseCaseCapsule__');
$ucobj->set_version('6.5.4');
my $comobj = &create_object('c__HP::Capsule::Common__');

$obj->add_case();

my $result = $obj->number_cases();
is ( $result eq 0, 1);

$obj->add_case($comobj);
$result = $obj->number_cases();
is ( $result eq 0, 1);
$result = $obj->number_cases('oo');
is ( $result eq 0, 1);
$result = $obj->number_cases('usecase');
is ( $result eq 0, 1);

$obj->add_case($oocobj);
$result = $obj->number_cases();
is ( $result eq 1, 1);
$result = $obj->number_cases('oo');
is ( $result eq 1, 1);
$result = $obj->number_cases('usecase');
is ( $result eq 0, 1);

$obj->add_case($ucobj, 'usecase');
$result = $obj->number_cases();
is ( $result eq 2, 1);
$result = $obj->number_cases('oo');
is ( $result eq 1, 1);
$result = $obj->number_cases('usecase');
is ( $result eq 1, 1);

&debug_obj($obj);