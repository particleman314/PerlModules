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
  }

my $version = '1.2.3';
my $vobj = &create_object('c__HP::VersionObject__');
is ( defined($vobj), 1 );

is ( $vobj->get_version_delimiter() eq '.', 1 );
&debug_obj($vobj);

$vobj->set_field_size({'minor' => 2, 'subrevision' => 4});

my $size = $vobj->get_field_size('major');
is ( $size == 2, 1 );

$size = $vobj->get_field_size();
is ( $size == 2, 1 );

$size = $vobj->get_field_size('blah');
is ( (not defined($size)), 1 );

$size = $vobj->get_field_size('subrevision');
is ( $size == 4, 1 );

$vobj->set_version($version);
$size = $vobj->get_field_size('subrevision');
is ( (not defined($size)), 1 );

$size = $vobj->get_field_size('minor');
is ( $size == 1, 1 );

debug_obj($vobj);
