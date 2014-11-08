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

$mjob->add_parameters({'name' => 'first_param', 'value' => 1});
$mjob->add_parameters({'name' => 'second_param', 'value' => 2});
$mjob->add_parameters({'name' => 'third_param', 'value' => 3});
$mjob->add_parameters({'name' => 'fourth_param', 'value' => 4});
$mjob->add_parameters({'name' => 'fifth_param', 'value' => 5});

is ( $mjob->flags()->number_elements() == 5, 1 );

&debug_obj($mjob);

my $jf = &create_object('c__HP::Job::ExecutableFlag__');
$jf->set_name('third_param');
$jf->set_value(3);

$mjob->remove_parameters($jf);
is ( $mjob->flags()->number_elements() == 4, 1 );
is ( $mjob->flags()->contains($jf) eq FALSE, 1 );

&debug_obj($mjob);
