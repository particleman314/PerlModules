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

my $pa = &create_object('c__HP::Job::ParameterArray__');
is ( defined($pa), 1 );

my $result = $pa->get_parameters();
is ( defined($result), 1 );
is ( ref($result) =~ m/^array/i, 1 );

my $flag = undef;

$result = $pa->add_flags($flag);
is ( $result eq FALSE, 1 );

$flag = 'SimpleFlag=XYZ';

$result = $pa->add_flags($flag);
is ( $result eq FALSE, 1 );

$flag = &create_object('c__HP::Job::ExecutableFlag__');
$result = $pa->add_flags($flag);
is ( $result eq FALSE, 1 );

$flag->set_name('SimpleFlag');
$flag->set_value('XYZ');

$result = $pa->add_flags($flag);
is ( $result eq TRUE, 1 );

my $flag2 = &create_object('c__HP::Job::ExecutableFlag__');
$flag2->set_name('SimpleFlag');
$flag2->set_value('XYZ');
$result = $pa->add_flags($flag2);
is ( $result eq TRUE, 1 );

&debug_obj($pa);