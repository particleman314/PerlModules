#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Os');
	use_ok('HP::Path');
	use_ok('HP::Array::Constants');
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

my $found = $job->find_flag('ComplexFlag');
is ( $found ne NOT_FOUND, 1 );

$found = $job->find_flag('NonExistentFlag');
is ( $found eq NOT_FOUND, 1 );

&debug_obj($job);
