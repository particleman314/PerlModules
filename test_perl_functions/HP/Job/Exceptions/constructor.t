#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Job');
	use_ok('HP::Job::Exception::NoExecutable');
}

my $ex = HP::Job::Exception::NoExecutable->new();
is ( defined($ex), 1 );

print STDERR $ex;

&debug_obj($ex);