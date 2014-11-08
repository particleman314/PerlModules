#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::CSL::Tools');
    use_ok('HP::Capsule::Tools');
	use_ok('HP::Capsule::Constants');
  }
  
my $gsf = "$FindBin::Bin/../../SettingsFiles/global_settings_testfile.xml";
my $lsf = "$FindBin::Bin/../../SettingsFiles/local_settings_testfile.xml";

&collect_global_settings("$gsf");
&collect_local_settings(undef, "$lsf");
&HP::CSL::Tools::extract_warehouses();

my $result = &generate_version();
is ( $result eq NULLVERSION, 1 );

$result = &generate_version(undef);
is ( $result eq NULLVERSION, 1 );

$result = &generate_version('ABC');
is ( $result eq NULLVERSION, 1 );

$result = &generate_version('DMA Application Provider for Provisioning Oracle');
#is ( $result eq NULLVERSION, 1 );
