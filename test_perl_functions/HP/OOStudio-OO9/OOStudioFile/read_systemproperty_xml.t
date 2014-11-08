#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::OOStudio::Constants');
	use_ok('HP::Path');
	use_ok('HP::DBContainer');
  }

# System Property Type XML file
# Reduced System Property XML File
#my $uuidfile = '2e9a44f1-3270-4acc-9f26-ffbbfcdc6909.xml';
my $uuidfile = '2e9a44f1-3270-4acc-9f26-ffbbfcdc6908.xml';
my $ooobj = &create_object('c__HP::OOStudio::OOStudioFile__');
is ( defined($ooobj), 1 );

my $driveDB = &getDB('drive');

$ooobj->oostudio_type(OO_VERSION_9);
my $xmlfile = &path_to_unix($driveDB->collapse_drivepath("$FindBin::Bin/samples/$uuidfile"));
$ooobj->readfile( "$xmlfile" );

&debug_obj($ooobj);
