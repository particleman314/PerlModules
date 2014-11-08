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
	use_ok('HP::DBContainer');
}

&createDBs();
my $mjob = &create_object('c__HP::Job::Maven__');
is ( defined($mjob), 1 );

$mjob->add_targets('clean');
$mjob->add_targets('build');
$mjob->add_targets('test');

is ( $mjob->targets()->number_elements() == 3, 1 );

&debug_obj($mjob);

$mjob->remove_targets('test');
is ( $mjob->targets()->number_elements() == 2, 1 );
is ( $mjob->targets()->contains('clean') eq TRUE, 1 );
is ( $mjob->targets()->contains('configure') eq FALSE, 1 );
is ( $mjob->targets()->contains('test') eq FALSE, 1 );

&debug_obj($mjob);
&shutdownDBs();