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
  }
  
my $obj = &create_object('c__HP::CapsuleMetadata::UseCase__');
is ( defined($obj), 1 );

my $uc_xmlfile = "$FindBin::Bin/../../SettingsFiles/test_usecase_manifest.xml";
$obj->readfile("$uc_xmlfile");
&debug_obj($obj);