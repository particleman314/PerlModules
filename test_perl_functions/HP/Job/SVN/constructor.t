#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Job::SVN');
	use_ok('HP::DBContainer');
}

&createDBs();
my $mjob = HP::Job::SVN->new();
is ( defined($mjob), 1 );

&debug_obj($mjob);
&shutdownDBs();