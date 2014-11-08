#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('Time::HiRes');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::CSL::Tools');
  }
  
my $settingspath = "$FindBin::Bin/../SettingsFiles";
my $obj = &create_object('c__HP::Capsule::CapsuleDirective__');
is ( defined($obj), 1 );

my $gsf = "$settingspath/global_settings_testfile.xml";
&collect_global_settings("$gsf");

my $xmlfile = "$settingspath/sample_capsule.xml";

my $bgtime   = Time::HiRes::time();
$obj->readfile("$xmlfile");
my $edtime   = Time::HiRes::time();

my $delta = $edtime - $bgtime;
&diag("Time used to read << $xmlfile >> is");
&diag($delta . " seconds");

#&debug_obj($obj);