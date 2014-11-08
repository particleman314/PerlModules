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
my $template = &get_template_obj($sobj->version());
is ( defined($template), 1 );

my $vobj = $template->clone();
$vobj->version('4.01');
$vobj->update();

$sobj->add_version_item($vobj);
my $items = $sobj->get_version_items();
is ( scalar(@{$items}) == 4, 1 );

my $vobj2 = $template->clone();
$vobj2->version('4.00');
$vobj2->update();

$sobj->add_version_item($vobj2);  # No checks for duplication
$items = $sobj->get_version_items();
is ( scalar(@{$items}) == 4, 1 );

&debug_obj($sobj);
