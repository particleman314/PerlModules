#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::LockDB');
}

my $lockDB = HP::LockDB->instance();
is ( defined($lockDB), 1 );

&debug_obj($lockDB);
