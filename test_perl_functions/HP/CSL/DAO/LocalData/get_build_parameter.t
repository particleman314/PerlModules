#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::CSL::DAO::LocalData__');
is ( defined($obj), 1 );

my $lsf = "$FindBin::Bin/../../../SettingsFiles/local_settings_testfile.xml";

$obj->readfile("$lsf");
is ( defined($obj->build_section()->configuration()->{'human'}), 1 );

my $result = $obj->get_build_parameter('human->name');
is ( defined($result), 1 );
&debug_obj($result);

&debug_obj($obj);