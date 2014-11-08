#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Capsule::Tools');
	use_ok('HP::CSL::Tools');
  }
  
my $gsf = "$FindBin::Bin/../../SettingsFiles/global_settings_testfile.xml";
&collect_global_settings("$gsf");
&HP::CSL::Tools::extract_warehouses();

my $capsule = &get_matching_provider();
is ( (not defined($capsule)), 1 );

$capsule = &get_matching_provider(undef);
is ( (not defined($capsule)), 1 );

$capsule = &get_matching_provider('ABCXYZ');
is ( (not defined($capsule)), 1 );

$capsule = &get_matching_provider('HP-Service Manager');
is ( defined($capsule), 1 );

&debug_obj($capsule);