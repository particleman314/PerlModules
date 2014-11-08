#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Job::JobOutput');
}

my $jobout = HP::Job::JobOutput->new();
is ( defined($jobout), 1 );

&debug_obj($jobout);