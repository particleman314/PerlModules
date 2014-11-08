#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::OOStudio::WorkflowCollection');
  }

my $wfobj1 = HP::OOStudio::WorkflowCollection->new();
is ( defined($wfobj1), 1 );

&debug_obj($wfobj1);


