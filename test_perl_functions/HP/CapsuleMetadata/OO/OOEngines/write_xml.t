#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::FileManager');
	use_ok('HP::DBContainer');
  }
  
&createDBs();
my $obj = &create_object('c__HP::CapsuleMetadata::OO::OOEngines__');
is ( defined($obj), 1 );

my $oo_xmlfile = "$FindBin::Bin/../../../SettingsFiles/test_oo_manifest-ooengines.xml";
$obj->readfile("$oo_xmlfile");

my $testoutput = "$FindBin::Bin/test_writing.xml";
&delete("$testoutput");

$obj->write_xml("$testoutput");
is ( &does_file_exist("$testoutput") eq TRUE, 1 );

&delete("$testoutput");
&debug_obj($obj);
&shutdownDBs();