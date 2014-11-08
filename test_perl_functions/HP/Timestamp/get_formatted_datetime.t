#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::Timestamp");
  }

my $testdir      = &MakeTempDir('TIMING');
my $result_UTC   = &get_formatted_datetime();
my $result_local = &get_formatted_datetime('local');

is((defined($result_UTC)),1);
is((defined($result_local)),1);
is(($result_UTC ne $result_local),1);

my $offset_time = &get_formatted_datetime('local', { 'day_offset' => -3 });
is((defined($offset_time)),1);
is(($result_local ne $offset_time),1);

rmtree("$testdir");

