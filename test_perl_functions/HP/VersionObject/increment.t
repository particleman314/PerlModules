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

my $version = '1.2.3.4';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_field_size(1);

$vobj->set_version($version);
is ( defined($vobj), 1 );
my $vout = $vobj->get_version();
is ( $vout eq $version, 1 );

&debug_obj($vobj);

$vobj->set_field_size(2);

$vobj->increment();
$vout = $vobj->get_version();
is ( $vout eq '2.00.00.00', 1 );

$vobj->increment('major');
$vout = $vobj->get_version();
is ( $vout eq '3.00.00.00', 1 );

$vobj->increment('revision');
$vout = $vobj->get_version();
is ( $vout eq '3.00.01.00', 1 );

$vobj->increment('minor');
$vout = $vobj->get_version();
is ( $vout eq '3.01.00.00', 1 );

$vobj->set_field_size(1);

$vobj->increment('minor');
$vout = $vobj->get_version();
is ( $vout eq '3.2.0.0', 1 );

$vobj->set_field_size(4);

$vobj->increment('subrevision');
$vout = $vobj->get_version();
is ( $vout eq '3.0002.0000.0001', 1 );

$vobj->set_field_size(2);

$vobj->increment('subrevision', 10);
$vout = $vobj->get_version();
is ( $vout eq '3.02.00.11', 1 );

$vobj->set_field_size(1);

$vobj->increment('major', 10);
$vout = $vobj->get_version();
is ( $vout eq '13.0.0.0', 1 );

&debug_obj($vobj);
