#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('UUID::Tiny');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
	use_ok('HP::OOStudio::Tools');
	use_ok('HP::OOStudio::Constants');
  }

my $uuid1 = ZERO_UUID;
&debug_obj($uuid1);
my $result = is_zero_uuid($uuid1);
is ( $result eq TRUE, 1 );

$uuid1 = &UUID::Tiny::uuid_to_string(&create_UUID(UUID_V4));
&debug_obj($uuid1);
$result = is_zero_uuid($uuid1);
is ( $result eq FALSE, 1);