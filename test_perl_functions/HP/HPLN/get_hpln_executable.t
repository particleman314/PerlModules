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

my $exe = $obj->get_hpln_executable();
is ( (not defined($exe)), 1 );

$obj->hpln_jarfile('xyz.jar');
$exe = $obj->get_hpln_executable();
is ( defined($exe), 1 );

my $hplnidxgenpath = "$FindBin::Bin/../../../../../library/oo/HPLN";
diag(&normalize_path("$hplnidxgenpath"));
$obj->hpln_jarfile(&join_path("$hplnidxgenpath", 'hpln-index-generator-1.20.jar'));
$exe = $obj->get_hpln_executable();
is ( defined($exe), 1 );

&debug_obj($obj);

my $exe2 = $obj->get_hpln_executable();
is ( defined($exe2), 1 );
&shutdownDBs();