#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Path');
	use_ok('HP::DBContainer');
  }
  
&createDBs();
my $obj = &create_object('c__HP::HPLN::IndexGenerator__');
is ( defined($obj), 1 );

my $hplnidxgenpath = "$FindBin::Bin/../../../../../library/oo/HPLN";
$obj->hpln_jarfile(&join_path("$hplnidxgenpath", 'hpln-index-generator-1.20.jar'));

my $jarpath = "$FindBin::Bin/../SettingsFiles/sample_jars";
$obj->index_directory(&normalize_path("$jarpath"));

my $status = $obj->run();
is ( $status eq PASS, 1 );
&debug_obj($obj);
&shutdownDBs();