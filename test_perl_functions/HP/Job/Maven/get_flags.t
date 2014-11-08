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
	use_ok('HP::Array::Tools');
}

my $mjob = &create_object('c__HP::Job::Maven__');
is ( defined($mjob), 1 );

$mjob->add_defines('defparam1');
$mjob->add_defines('defparam2');

$mjob->add_parameters({'name' => 'my_special_param', 'value' => 1});
$mjob->add_parameters({'name' => 'another', 'value' => 'value'});

$mjob->add_targets('clean');
$mjob->add_targets('build');

my $result = $mjob->get_flags();
is ( defined($result), 1 );
is ( $result =~ m/build/ eq TRUE, 1 );
is ( $result =~ m/my_special_param/ eq TRUE, 1 );

&debug_obj($result);
&debug_obj($mjob);