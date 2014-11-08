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

my $vobj = &create_object('c__HP::VersionObject__');
is ( defined($vobj), 1 );

my $value = '1';
my $result = $vobj->__update_field($value);
is ( $result eq length($value), 1 );

$value = '10';
$result = $vobj->__update_field($value);
is ( $result eq length($value), 1 );

$value = '01';
$result = $vobj->__update_field($value);
is ( $result eq length($value), 1 );

$value = 'A';
$result = $vobj->__update_field($value);
is ( ( not defined($result) ), 1 );

&debug_obj($vobj);


