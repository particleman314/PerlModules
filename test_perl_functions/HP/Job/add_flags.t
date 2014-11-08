#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
}

my $job = &create_object('c__HP::Job__');
is ( defined($job), 1 );

my $flag = &create_object('c__HP::Job::ExecutableFlag__');
$flag->set_name('SimpleFlag');
$flag->set_value('XYZ');

$job->add_flags($flag);
is ( $job->flags()->number_elements() eq 1, 1 );

$job->add_flags('NotSoSimpleFlag');
is ( $job->flags()->number_elements() eq 2, 1 );

my $refflag = 'RefSimpleFlag';
$job->add_flags(\$refflag);
is ( $job->flags()->number_elements() eq 3, 1 );

my $hashflag = {
                'name' => 'ComplexFlag',
				'value' => '2',
				'connector' => '->',
               };
$job->add_flags($hashflag);
is ( $job->flags()->number_elements() eq 4, 1 );

$job->add_flags('PositionalFlag1', 1);
is ( $job->flags()->number_elements() eq 5, 1 );

$job->add_flags('PositionalFlag2', 3);
is ( $job->flags()->number_elements() eq 6, 1 );

my $result = $job->get_flag_at(0);  # 0-offset for internal array notification
is ( defined($result), 1 );
is ( $result->name() eq 'PositionalFlag1', 1 );

$result = $job->get_flag_at(2);  # 0-offset for internal array notification
is ( defined($result), 1 );
is ( $result->name() eq 'PositionalFlag2', 1 );

&debug_obj($result);

&debug_obj($job);
