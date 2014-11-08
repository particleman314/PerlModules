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
	use_ok('HP::Support::Object');
  }
my $sobj = &create_object('c__HP::Providers::Support__');
is ( defined($sobj), 1 );

my $xmlfile = "$FindBin::Bin/../../SettingsFiles/sample_support.xml";
$sobj->readfile("$xmlfile");

$sobj->cleanup_internals();
my $version2find = '4.01';

my $result = $sobj->has_version($version2find);
is ( $result eq FALSE, 1 );

$version2find = '3.20';
$result = $sobj->has_version($version2find);
is ( $result eq TRUE, 1 );

my $template = &get_template_obj($sobj->version());
is ( defined($template), 1 );

$version2find = $template->clone();
$version2find->version('4.00');
$version2find->update();
$result = $sobj->has_version($version2find);
is ( $result eq TRUE, 1 );

&debug_obj($sobj);
