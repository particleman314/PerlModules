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
$oocobj->name('System Generator');
my $ucobj1  = &create_object('c__HP::Capsule::UseCaseCapsule__');
$ucobj1->set_version('6.5.4');
$ucobj1->workflow('MATLAB');
$ucobj1->usecase('MATLAB');
my $ucobj2  = &create_object('c__HP::Capsule::UseCaseCapsule__');
$ucobj2->set_version('7.0.1');
$ucobj2->workflow('MATLAB');
$ucobj2->usecase('MATLAB');
my $ucobj3  = &create_object('c__HP::Capsule::UseCaseCapsule__');
$ucobj3->set_version('7.1.0');
$ucobj3->workflow('MATLAB');
$ucobj3->usecase('MATLAB');

$obj->add_case($oocobj);
$obj->add_case($ucobj1);
$obj->add_case($ucobj2);
$obj->add_case($ucobj3);

my $result = $obj->find_usecase_capsule();
is ( (not defined($result)), 1 );

$result = $obj->find_usecase_capsule('MATLAB');
is ( defined($result), 1 );
is ( scalar(@{$result}) == 3, 1 );

$result = $obj->find_usecase_capsule('System Generator');
is ( (not defined($result)), 1 );

$result = $obj->find_oo_capsule('System Generator');
is ( defined($result), 1 );
is ( $result->get_type() eq 'oo', 1 );

&debug_obj($obj);