#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Job::Constants');
	use_ok('HP::Os');
	use_ok('HP::Path');
	use_ok('HP::DBContainer');
}

&createDBs();
my $job = &create_object('c__HP::Job__');
is ( defined($job), 1 );

$job->add_flags('/W');
$job->add_flags('/B');

my $exename = 'dir';
$job->set_executable($exename, BUILTIN);

$job->run();

&debug_obj($job);
&shutdownDBs();