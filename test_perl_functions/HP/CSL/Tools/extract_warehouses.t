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
  
my $result = &HP::CSL::Tools::extract_warehouses();
is ( $result eq TRUE, 1 );
is ( (not defined($HP::CSL::Tools::__global_datastore) ), 1 );
is ( (not defined($HP::CSL::Tools::__local_datastore) ), 1 );

my $gsf = "$FindBin::Bin/../../SettingsFiles/global_settings_testfile.xml";
&collect_global_settings("$gsf");

$result = &HP::CSL::Tools::extract_warehouses();
is ( $result eq TRUE, 1 );
is ( defined($HP::CSL::Tools::__global_datastore), 1 );
is ( (not defined($HP::CSL::Tools::__local_datastore) ), 1 );
