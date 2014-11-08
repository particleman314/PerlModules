#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../../..";
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
my $input_xmlfile  = "$FindBin::Bin/test_usecase_manifest-dependency.xml";
my $output_xmlfile = "$FindBin::Bin/test_usecase_manifest-dependency-output.xml";

&delete("$output_xmlfile");

my $obj = &create_object('c__HP::CapsuleMetadata::UseCase::Dependency__');
is ( defined($obj), 1 );

$obj->readfile("$input_xmlfile");

my $result = $obj->write_xml("$output_xmlfile");
is ( $result eq TRUE, 1 );

my $xmldiff = XML::SemanticDiff->new();
my @results = $xmldiff->compare("$input_xmlfile", "$output_xmlfile");

my $expected_diffs = 0;
is ( scalar(@results) == $expected_diffs, 1 );

&delete("$output_xmlfile") if ( scalar(@results) == $expected_diffs );

&debug_obj($obj);
&shutdownDBs();