#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::OOStudio::Constants');
 }

my $ooobj = &create_object('c__HP::OOStudio::OOStudioFile__');
is ( defined($ooobj), 1 );

$ooobj->oostudio_type(OO_VERSION_10);

my $xmlfile = "$FindBin::Bin/samples/Alert.xml";
$ooobj->readfile( "$xmlfile" );

is ( $ooobj->filename() eq "$xmlfile", 1);
&debug_obj($ooobj);


