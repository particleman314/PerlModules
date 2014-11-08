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
  
my $oocobj = &create_object('c__HP::Capsule::OOCapsule__');
my $ucobj  = &create_object('c__HP::Capsule::UseCaseCapsule__');

is ( defined($oocobj), 1 );
is ( defined($ucobj), 1 );

is ( (not defined($oocobj->get_version())), 1 );

$ucobj->workflow('TrialOOCase');
$ucobj->usecase($ucobj->workflow());
$ucobj->set_version('1.5.4');

$oocobj->convert_usecase_capsule();
is ( (not defined($oocobj->get_version())), 1 );

$oocobj->convert_usecase_capsule($ucobj);
is ( defined($oocobj->get_version()), 1 );
is ( $oocobj->get_version() eq '1.5.4', 1 );

&debug_obj($ucobj);
&debug_obj($oocobj);
