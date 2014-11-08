#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Job');
	use_ok('HP::Job::ExecutableFlag');
	use_ok('HP::Job::Executable');
	use_ok('HP::Job::JobOutput');
}

my $job = HP::Job->new();
is ( defined($job), 1 );

print STDERR $job;

my $job_flag = HP::Job::ExecutableFlag->new();
is ( defined($job_flag), 1 );

my $exe = HP::Job::Executable->new();
is ( defined($exe), 1 );

my $jobout = HP::Job::JobOutput->new();
is ( defined($jobout), 1 );

&debug_obj($job);
&debug_obj($job_flag);
&debug_obj($exe);
&debug_obj($jobout);