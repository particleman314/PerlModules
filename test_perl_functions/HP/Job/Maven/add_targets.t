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

my $mjob = &create_object('c__HP::Job::Maven__');
is ( defined($mjob), 1 );

$mjob->add_targets('clean');
$mjob->add_targets('build');

is ( $mjob->targets()->number_elements() == 2, 1 );

&debug_obj($mjob);