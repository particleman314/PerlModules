#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Job::ExecutableFlag');
}

my $job_flag = HP::Job::ExecutableFlag->new();
is ( defined($job_flag), 1 );

&debug_obj($job_flag);
