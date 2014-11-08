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
	use_ok('HP::FileManager');
	use_ok('HP::DBContainer');
  }

&createDBs();
my $version = '9.1.05';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );
&debug_obj($vobj);

my $filename = "$FindBin::Bin/../SettingsFiles/sample_version.xml";

$vobj->readfile($filename);

is ( $vobj->get_version_delimiter() eq '.', 1 );
is ( $vobj->get_version() ne $version, 1 );

my $outputfile = "$FindBin::Bin/output_version.xml";
if ( &does_file_exist("$outputfile") eq TRUE ) {
  &delete("$outputfile");
}

$vobj->writefile("$outputfile");

is ( &does_file_exist("$outputfile") eq TRUE, 1 );

my $vobj2 = &create_object('c__HP::VersionObject__');
$vobj2->readfile("$outputfile");

is ( $vobj2->get_version() eq '10.10.01', 1 );
&debug_obj($vobj2);

&delete("$outputfile");

&debug_obj($vobj);
&shutdownDBs();


