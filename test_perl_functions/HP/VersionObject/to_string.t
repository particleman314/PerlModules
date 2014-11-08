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

my $version = '1.20.300';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );

is ( $vobj->get_version() eq $version, 1 );

my $vobj2 = &create_object('c__HP::VersionObject__');
$vobj2->set_version_delimiter('_');
$vobj2->set_version('1_2_3');
is ( defined($vobj2), 1 );

is ( $vobj2->get_version() eq '1_2_3', 1 );

my $result = $vobj2->to_string();
is ( $result eq '1_2_3', 1 );

$vobj2->modify_output_representation(MAJOR_MINOR);
$result = $vobj2->to_string();
is ( $result eq '1_2', 1 );

&debug_obj($vobj2);


