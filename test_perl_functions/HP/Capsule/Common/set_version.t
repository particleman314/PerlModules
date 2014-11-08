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
  
my $oocobj = &create_object('c__HP::Capsule::Common__');
is ( defined($oocobj), 1 );

$oocobj->selection('TrialOOCase');
$oocobj->set_version('1.5.4');

is ( $oocobj->version()->get_version() eq '1.5.4', 1 );
is ( $oocobj->version()->get_version_delimiter() eq '.', 1 );
is ( $oocobj->selection() eq 'TrialOOCase', 1 );

&debug_obj($oocobj);

my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version('10.01.01');
$oocobj->set_version($vobj);

is ( $oocobj->version()->get_version() eq '10.01.01', 1 );
is ( $oocobj->version()->get_version_delimiter() eq '.', 1 );

&debug_obj($oocobj);

my $vobj2 = &create_object('c__HP::VersionObject__');
$vobj2->set_version_delimiter('-');
$vobj2->set_version('10-01-01');
$oocobj->set_version($vobj2);

is ( $oocobj->version()->get_version() eq '10-01-01', 1 );
is ( $oocobj->version()->get_version_delimiter() eq '-', 1 );

&debug_obj($oocobj);

$oocobj->set_version('1_2_3', '_');

is ( $oocobj->version()->get_version() eq '1_2_3', 1 );
is ( $oocobj->version()->get_version_delimiter() eq '_', 1 );

&debug_obj($oocobj);
