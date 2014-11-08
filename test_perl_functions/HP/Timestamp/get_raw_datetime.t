#!/usr/bin/env perl

use strict;
use FindBin;
use lib "$FindBin::Bin/../../..";
use lib "$FindBin::Bin/../../../PerlModules";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::Timestamp");
  }

my $testdir = &MakeTempDir('TIMING');

is(length(&get_raw_datetime()), 14);
is(length(&get_raw_datetime(1)), 14);
is(length(&get_raw_datetime(-1)), 14);

rmtree("$testdir");
