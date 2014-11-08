#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
}

my $job_flag = &create_object('c__HP::Job::ExecutableFlag__');
is ( defined($job_flag), 1 );

$job_flag->set_name('SimpleFlag');
is ( $job_flag->name() eq 'SimpleFlag', 1 );
is ( $job_flag->valid() eq TRUE , 1);

&debug_obj($job_flag);
