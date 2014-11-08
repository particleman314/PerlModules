#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::CSL::Tools');
  }
  
my $gsf = "$FindBin::Bin/../../SettingsFiles/global_settings_testfile.xml";
&collect_global_settings("$gsf");
&HP::CSL::Tools::extract_warehouses();

my $result = &get_global_datastore();
is ( defined($result), 1 );