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
	use_ok('HP::Stream::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::FileManager');
  }

my $testXMLfile = "$FindBin::Bin/../../SettingsFiles/test_output.xml";
is ( &does_file_exist( "$testXMLfile" ) eq TRUE, 1 );

my $streamDB = &create_instance('c__HP::StreamDB__');

my $teststream = $streamDB->make_stream("$testXMLfile", INPUT, '__TEST__');
my $xmloutput = join('',@{$teststream->slurp()});

my $sample = &clone_item($xmloutput);

$xmloutput = &remove_xml_header($sample, FALSE);
is ( &equal($xmloutput,$sample) eq TRUE, 1 );

$xmloutput = &remove_xml_header($sample, TRUE);
is ( &equal($xmloutput,$sample) eq FALSE, 1 );

&debug_obj($sample);
&debug_obj($xmloutput);