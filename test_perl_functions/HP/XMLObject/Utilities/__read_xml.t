#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Utilities');
    use_ok('HP::XML::Utilities');
	use_ok('HP::Support::Object::Tools');
  }

my $testXMLfile = "$FindBin::Bin/../../SettingsFiles/test_output.xml";
is ( -f "$testXMLfile", 1 );

my $objtemplate = { 'subnode' => { 'build_date' => undef, 'build_number' => undef, 'svn_revision' => undef } };
my $testobj = &create_object($objtemplate);

my $xmlobj = &create_object('c__HP::XMLObject__');
is ( defined($xmlobj) == 1, 1 );

$xmlobj->xmlfile("$testXMLfile");
$xmlobj->readfile();

my $result = &HP::XML::Utilities::__read_xml($testobj, $xmlobj->rootnode());
is ( $result eq TRUE, 1);

&debug_obj($testobj);