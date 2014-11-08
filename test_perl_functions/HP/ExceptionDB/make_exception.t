#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
  }

my $exDB = &create_instance('c__HP::ExceptionDB__');
is ( $exDB->number_exceptions() == 0, 1);

my $pe  = { 'personal_exception1' => [ 4, 'HP::Copy::Exceptions::CopyFailureException' ],
            'personal_exception2' => [ 5, 'HP::Copy::Exceptions::CopyFailureException' ],
			'personal_exception3' => [ 23, 'HP::Copy::Exceptions::CopyFailureException' ],
			'personal_exception4' => [ 67, 'HP::Copy::Exceptions::CopyFailureException' ],
			'personal_exception5' => [ -90, 'HP::Copy::Exceptions::CopyFailureException' ],
			'personal_exception6' => [ -90, 'HP::Copy::Exceptions::CopyFailureException' ],
			'personal_exception7' => [ -254, 'HP::Copy::Exceptions::CopyFailureException' ], };

$exDB->install_exception_types($pe);
is ( $exDB->number_exceptions() == 6, 1);

my $exception1 = $exDB->make_exception('name', 'personal_exception3');
is ( defined($exception1), 1 );

my $exception2 = $exDB->make_exception('id', 254);
is ( defined($exception2), 1 );

my $exception3 = $exDB->make_exception('id', 1);
is ( (not defined($exception3)), 1 );

&debug_obj($exDB);