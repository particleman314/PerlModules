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
  }
  
my $obj = &create_object('c__HP::CapsuleMetadata::OO::OOEngineFolder__');
is ( defined($obj), 1 );

my $oo_xmlfile = "$FindBin::Bin/test_oo_manifest-ooenginefolder.xml";
$obj->readfile("$oo_xmlfile");

&debug_obj($obj);