#!/usr/bin/env perl

use strict;
use FindBin;
use lib "$FindBin::Bin/../../..";
use lib "$FindBin::Bin/../../../PerlModules";

use Test::More qw(no_plan);
use Time::HiRes;

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::Timestamp");
  }

my $testdir      = &MakeTempDir('TIMING');
my $result_UTC   = &get_formatted_time_hires();
my $result_local = &get_formatted_time_hires('local');

is((defined($result_UTC)),1);
is((defined($result_local)),1);
is(($result_UTC ne $result_local),1);

rmtree("$testdir");
