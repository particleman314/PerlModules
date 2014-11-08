#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use lib "$FindBin::Bin/../../../PerlModules";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::Timestamp");
  }

my $testdir  = &MakeTempDir('TIMING');

my $date1      = '2009-01-01';
my $date1_hash = &make_hash($date1);

my $date2      = '2008-12-31';
my $date2_hash = &make_hash($date2);

my $date3      = '2009-01-31';
my $date3_hash = &make_hash($date3);

my $date4      = undef;
my $date4_hash = undef;

my $result = &get_date_difference($date1, $date2);
is((not defined($result)),1);

$result = &get_date_difference($date1_hash, $date2);
is((not defined($result)),1);

$result = &get_date_difference($date1, $date2_hash);
is((not defined($result)),1);

$result = &get_date_difference($date1_hash, $date2_hash);
is((defined($result)),1);
is($result,-1);

$result = &get_date_difference($date2_hash, $date1_hash);
is((defined($result)),1);
is($result,1);

$result = &get_date_difference($date1_hash, $date3_hash);
is((defined($result)),1);
is($result,30);

$result = &get_date_difference($date1_hash, $date4_hash);
is(( not defined($result)),1);

rmtree("$testdir");

sub make_hash($)
  {
    my $date = shift;
    my @comps = split('-',$date);
    my $date_h = {
		  'year'    => "$comps[0]",
		  'month'   => "$comps[1]",
		  'day'     => "$comps[2]",
		  'hours'   => '0',
		  'minutes' => '0',
		  'seconds' => '0',
		 };
    return $date_h;
  }

