#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Version::Constants');
  }

my $vobj = &create_object('c__HP::VersionObject__');
is ( defined($vobj), 1 );

is ( $vobj->style() eq XMLNODES, 1 );

$vobj->as_attribute();
is ( $vobj->style() eq XMLATTR, 1 );

$vobj->as_node();
is ( $vobj->style() eq XMLNODES, 1 );

&debug_obj($vobj);


