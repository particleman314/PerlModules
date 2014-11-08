#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::FileManager');
	use_ok('XML::SemanticDiff');
	use_ok('HP::DBContainer');
  }

&createDBs();
my $input_xmlfile  = "$FindBin::Bin/../../SettingsFiles/test_capsule_pack_manifest.xml";
my $output_xmlfile = "$FindBin::Bin/test_capsule_pack_manifest-output.xml";

&delete("$output_xmlfile");
my $obj = &create_object('c__HP::CapsuleMetadata::CloudCapsule__');
is ( defined($obj), 1 );

$obj->readfile("$input_xmlfile");

&debug_obj($obj);

my $result = $obj->write_xml("$output_xmlfile");
is ( $result eq TRUE, 1 );

my $xmldiff = XML::SemanticDiff->new();
my @results = $xmldiff->compare("$input_xmlfile", "$output_xmlfile");

my $expected_diffs = 0;
is ( scalar(@results) == $expected_diffs, 1 );

&debug_obj($obj);

&debug_obj(\@results) if ( scalar(@results) != $expected_diffs );
&delete("$output_xmlfile");
&shutdownDBs();