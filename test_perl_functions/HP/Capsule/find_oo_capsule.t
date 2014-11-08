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

my $ucobj = &create_object('c__HP::Capsule::UseCaseCapsule__');
$ucobj->set_version('1.0.1');
$ucobj->workflow('System Generator');
$ucobj->usecase('System Generator');
my $oocobj1  = &create_object('c__HP::Capsule::OOCapsule__');
$oocobj1->set_version('6.5.4');
$oocobj1->name('MATLAB');
my $oocobj2  = &create_object('c__HP::Capsule::OOCapsule__');
$oocobj2->set_version('7.0.1');
$oocobj2->name('MATLAB');
my $oocobj3  = &create_object('c__HP::Capsule::OOCapsule__');
$oocobj3->set_version('7.1.0');
$oocobj3->name('MATLAB');

$obj->add_case($ucobj);
$obj->add_case($oocobj1);
$obj->add_case($oocobj2);
$obj->add_case($oocobj3);

my $result = $obj->find_oo_capsule();
is ( (not defined($result)), 1 );

$result = $obj->find_oo_capsule('MATLAB');
is ( defined($result), 1 );
is ( scalar(@{$result}) == 3, 1 );

$result = $obj->find_oo_capsule('System Generator');
is ( (not defined($result)), 1 );

$result = $obj->find_usecase_capsule('System Generator');
is ( defined($result), 1 );
is ( $result->get_type() eq 'usecase', 1 );

&debug_obj($obj);