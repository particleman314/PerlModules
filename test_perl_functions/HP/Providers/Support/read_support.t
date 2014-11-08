#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
	use_ok('HP::Providers::Support');
	use_ok('HP::Utilities');
  }
my $sobj = HP::Providers::Support->new();
is ( defined($sobj), 1 );

my $xmlfile = "$FindBin::Bin/../../SettingsFiles/sample_support.xml";
$sobj->readfile("$xmlfile");

$sobj->cleanup_internals();
&debug_obj($sobj);
