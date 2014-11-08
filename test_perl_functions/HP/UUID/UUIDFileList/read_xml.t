#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::UUID::Tools');
	use_ok('HP::UUID::Constants');
  }

my $output_xmlfile = "$FindBin::Bin/../../SettingsFiles/test_uuid_recording.xml";

my $obj2 = &create_object('c__HP::UUID::UUIDFileList__');

$obj2->readfile("$output_xmlfile");
is ( $obj2->jarfile_uuid() ne ZERO_UUID, 1 );
is ( scalar(@{$obj2->uuid_association()->get_elements()}) > 0, 1 );

&debug_obj($obj2);