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
  }
 
my $ooobj = &create_object('c__HP::OOStudio::OOStudioFile__');
is ( defined($ooobj), 1 );

my $xmlfile = "$FindBin::Bin/samples/Reduced DMA Deploy Application.xml";
#my $xmlfile = "$FindBin::Bin/samples/DMA Deploy Application.xml";
$ooobj->readfile( "$xmlfile" );

my $uuids_seen = $ooobj->get_uuids();

&debug_obj($uuids_seen);

# Should be much faster once cached...
$uuids_seen = $ooobj->get_uuids();
&debug_obj($uuids_seen);
&debug_print_dumper($ooobj);
