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

$mjob->add_parameters({'name' => 'my_special_param', 'value' => 1});
$mjob->add_parameters({'name' => 'another', 'value' => 'value'});

is ( $mjob->flags()->number_elements() == 2, 1 );

&debug_obj($mjob);