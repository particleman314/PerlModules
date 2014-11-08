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

$mjob->add_defines('one');
$mjob->add_defines('two');
$mjob->add_defines('three');
$mjob->add_defines('four');

is ( $mjob->defines()->number_elements() == 4, 1 );

&debug_obj($mjob);

$mjob->remove_defines('two');
is ( $mjob->defines()->number_elements() == 3, 1 );
is ( $mjob->defines()->contains('one') eq TRUE, 1 );
is ( $mjob->defines()->contains('two') eq FALSE, 1 );

&debug_obj($mjob);
&shutdownDBs();