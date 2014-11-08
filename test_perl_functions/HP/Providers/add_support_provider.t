#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Utilities');
  }
my $smobj = &create_object('c__HP::SupportMatrix__');
is ( defined($smobj), 1 );

my $xmlfile = "$FindBin::Bin/../SettingsFiles/sample_support_matrix.xml";
$smobj->readfile("$xmlfile");

is ( $smobj->number_providers() eq 2, 1);

my $added_provider = &create_object('c__HP::Providers::Support__');
$added_provider->name('com.hp.dma');
$added_provider->displayName('Database and Middleware Automation');
$added_provider->mandatory(&convert_boolean_to_string(FALSE));
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->version('10.21');
$added_provider->version()->push_item($vobj);

$smobj->add_provider($added_provider);
my $result = $smobj->has_provider('com.hp.dma');
is ( $result eq TRUE, 1 );
is ( $smobj->number_providers() eq 3, 1);

my $added_provider2 = &create_object('c__HP::Providers::Support__');
$added_provider2->name('com.hp.csa');
$added_provider2->displayName('Cloud Service Automation');
$added_provider2->mandatory(&convert_boolean_to_string(TRUE));
my $vobj2 = &create_object('c__HP::VersionObject__');
$vobj2->version('4.10');
$added_provider2->version()->push_item($vobj2);

$smobj->add_provider($added_provider2);
$result = $smobj->has_provider('com.hp.csa');
is ( $result eq TRUE, 1 );
is ( $smobj->number_providers() eq 3, 1);

$smobj->cleanup_internals();
&debug_obj($smobj);
