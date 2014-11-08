#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::CSL::Tools');
  }
  
my $gsf = "$FindBin::Bin/../../../SettingsFiles/global_settings_testfile.xml";
&collect_global_settings("$gsf");
&HP::CSL::Tools::extract_warehouses();

my $gds = &get_global_datastore();

my $name = $gds->get_normalized_provider_name();
is ( (not defined($name)), 1 );

$name = $gds->get_normalized_provider_name(undef);
is ( (not defined($name)), 1 );

$name = $gds->get_normalized_provider_name('ABCXYZ');
is ( (not defined($name)), 1 );

$name = $gds->get_normalized_provider_name('HP-Service Manager');
is ( defined($name), 1 );
is ( $name eq 'HP-Service Manager', 1 );

$name = $gds->get_normalized_provider_name('HP-SA-Patch');
is ( defined($name), 1 );
is ( $name eq 'HP-Server Automation Patching Compliance', 1 );

&debug_obj($name);

$name = $gds->get_normalized_provider_name('com.hp.csl.dma');
is ( defined($name), 1 );
is ( scalar(@{$name}) == 4, 1 );

my $setobj = &create_object('c__HP::Array::Set__');
$setobj->add_elements({'entries' => $name});

is ( $setobj->contains('HP-Database Middleware Automation SQL Server') eq TRUE, 1 );
is ( $setobj->contains('HP-Database Middleware Automation WebSphere') eq TRUE, 1 );

&debug_obj($name);
