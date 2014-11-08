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
my $input_xmlfile  = "$FindBin::Bin/../../SettingsFiles/test_usecase_manifest.xml";
my $output_xmlfile = "$FindBin::Bin/test_usecase_manifest-output.xml";

&delete("$output_xmlfile");
my $obj = &create_object('c__HP::CapsuleMetadata::UseCase__');
is ( defined($obj), 1 );

$obj->readfile("$input_xmlfile");

my $result = $obj->write_xml("$output_xmlfile");
is ( $result eq TRUE, 1 );

my $xmldiff = XML::SemanticDiff->new();
my @results = $xmldiff->compare("$input_xmlfile", "$output_xmlfile");

my $expected_diffs = 3;
is ( scalar(@results) == $expected_diffs, 1 );
is ( $results[0]->{'message'} eq 'Rogue attribute \'type\' in element \'blueprint\'.', 1 );
is ( $results[1]->{'message'} eq 'Rogue attribute \'mandatory\' in element \'provider\'.', 1 );
is ( $results[2]->{'message'} eq 'Rogue attribute \'mandatory\' in element \'provider\'.', 1 );

&debug_obj($obj);

&debug_obj(\@results) if ( scalar(@results) != $expected_diffs );
&shutdownDBs();