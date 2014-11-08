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
	use_ok('HP::DBContainer');
  }

&createDBs();

my $tobj = &create_object('c__HP::TestObject__');
is ( defined($tobj), 1 );

my $filename = "$FindBin::Bin/../SettingsFiles/sample_version.xml";
my $result = $tobj->readfile($filename);
is ( $result eq TRUE, 1 );

my $outfilename = "$FindBin::Bin/sample_output.xml";
$result = $tobj->writefile($outfilename);
is ( $result eq TRUE, 1 );

is ( -e "$outfilename", 1 );

&debug_obj($tobj);
&shutdownDBs();
