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
  
my $obj = &create_object('c__HP::CSL::DAO::GlobalData__');
is ( defined($obj), 1 );

my $gsf = "$FindBin::Bin/../../../SettingsFiles/global_settings_testfile.xml";

$obj->readfile("$gsf");

is ( defined($obj->build_section()->configuration()->{'OO9'}), 1 );

my $result = $obj->get_build_parameter('svn->tempfile');
is ( defined($result), 1 );
&debug_obj($result);

$result = $obj->get_build_parameter('OO10->oo->content->cpversion');
is ( defined($result), 1 );
&debug_obj($result);

$result = $obj->get_build_parameter('OO10->oo');
is ( defined($result), 1 );
&debug_obj($result);

$result = $obj->get_build_parameter('build');
is ( defined($result), 1 );
&debug_obj($result);

#&debug_obj($obj);