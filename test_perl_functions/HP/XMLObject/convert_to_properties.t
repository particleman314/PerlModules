#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Support::Configuration');
  }
  
my $obj = &create_object('c__HP::XMLObject__');
is (defined($obj) == 1, 1);

my $xmlfile = "$FindBin::Bin/../SettingsFiles/test_output.xml";
$obj->xmlfile("$xmlfile");
$obj->readfile();

my $result = $obj->convert_to_properties();
&debug_obj($result);

my $trial = {};
&debug_obj($trial);

my $success = &save_to_configuration({'table' => $trial, 'data' => $result});
is ( $success eq TRUE, 1 );

&debug_obj($trial);
&debug_obj( $obj );