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
my $smobj1 = &create_object('c__HP::SupportMatrix__');
my $smobj2 = &create_object('c__HP::SupportMatrix__');
is ( defined($smobj1), 1 );
is ( defined($smobj2), 1 );

my $xmlfile = "$FindBin::Bin/../SettingsFiles/sample_support_matrix.xml";
$smobj1->readfile("$xmlfile");
$smobj2->readfile("$xmlfile");

is ( $smobj1->number_providers() eq 2, 1);
is ( $smobj2->number_providers() eq 2, 1);

my $added_provider = &create_object('c__HP::Providers::Support__');
$added_provider->name('com.hp.dma');
$added_provider->displayName('Database and Middleware Automation');
$added_provider->mandatory(&convert_boolean_to_string(FALSE));
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->version('10.21');
$added_provider->version()->push_item($vobj);

$smobj1->add_provider($added_provider);
my $result = $smobj1->has_provider('com.hp.dma');
is ( $result eq TRUE, 1 );
is ( $smobj1->number_providers() eq 3, 1);

my $added_provider2 = &create_object('c__HP::Providers::Support__');
$added_provider2->name('com.hp.csa');
$added_provider2->displayName('Cloud Service Automation');
$added_provider2->mandatory(&convert_boolean_to_string(TRUE));
my $vobj2 = &create_object('c__HP::VersionObject__');
$vobj2->version('4.10');
$added_provider2->version()->push_item($vobj2);

$smobj1->add_provider($added_provider2);
$result = $smobj1->has_provider('com.hp.csa');
is ( $result eq TRUE, 1 );
is ( $smobj1->number_providers() eq 3, 1);

$smobj1->cleanup_internals();

$smobj2->add_support_matrix($smobj1);
is ( $smobj2->number_providers() eq 3, 1);
&debug_obj($smobj2);
