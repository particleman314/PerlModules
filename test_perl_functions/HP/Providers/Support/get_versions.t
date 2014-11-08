#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Utilities');
  }
my $sobj = &create_object('c__HP::Providers::Support__');
is ( defined($sobj), 1 );

my $xmlfile = "$FindBin::Bin/../../SettingsFiles/sample_support.xml";
$sobj->readfile("$xmlfile");

$sobj->cleanup_internals();
my $version_entries = $sobj->get_versions();
is ( scalar(@{$version_entries}) eq 3, 1 );

&debug_obj($version_entries);
&debug_obj($sobj);
