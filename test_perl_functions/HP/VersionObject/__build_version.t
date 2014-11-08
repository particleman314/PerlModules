#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Version::Constants');
  }

my $version = '1.2.3.4000';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );

is ( $vobj->get_version() eq $version, 1 );

$vobj->modify_output_representation(MAJOR_MINOR);
is ( $vobj->get_version() eq '1.2', 1);

$vobj->modify_output_representation(MAJOR_ONLY);
is ( $vobj->get_version() eq '1', 1);

$vobj->modify_output_representation(MAJOR_MINOR_REVISION);
is ( $vobj->get_version() eq '1.2.3', 1);

my $vobj2 = &create_object('c__HP::VersionObject__');
$version = '1.1.5-SNAPSHOT';

$vobj2->set_version($version);
is ( $vobj2->get_version() eq $version, 1 );

&debug_obj($vobj);
&debug_obj($vobj2);


