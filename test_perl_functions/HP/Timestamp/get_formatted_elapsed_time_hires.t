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

my $max_time_disparity = 15;
for ( my $testloop = 0; $testloop < $max_time_disparity; ++$testloop ) {
  my $result_now     = time();
  is((defined($result_now)),1);
  sleep($testloop) if ( $testloop );

  my $result_nowplus = &get_formatted_elapsed_time($result_now);
  is((defined($result_nowplus)),1);
}
rmtree("$testdir");
