#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::Array::Tools');
  }

my $numTestCases = 50;
for (my $testcases = 0; $testcases < $numTestCases; ++$testcases) {
  my $max    = &MakeNumbers(1,10000,1);
  my $intmax = int($max);
  my @input1 = ( 1 .. $intmax );

  my $output1a = &sum_array(\@input1);

  is($output1a, ($intmax * ($intmax + 1) / 2));
}

