#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Lock::TimedMutex');
}

my $lock = HP::Lock::TimedMutex->new();
is ( defined($lock), 1 );

&debug_obj($lock);
