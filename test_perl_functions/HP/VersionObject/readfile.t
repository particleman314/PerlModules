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
  }

my $version = '10.10.01';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );

my $filename = "$FindBin::Bin/../SettingsFiles/sample_version.xml";

$vobj->readfile($filename);

is ( $vobj->get_version_delimiter() eq '.', 1 );
is ( $vobj->get_version() eq $version, 1 );

&debug_obj($vobj);


