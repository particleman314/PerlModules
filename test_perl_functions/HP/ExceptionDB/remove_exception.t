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

my $pe  = { 'personal_exception1' => [ 4, 'HP::Copy::CopyFailureException' ],
            'personal_exception2' => [ 5, 'HP::Copy::CopyFailureException' ],
			'personal_exception3' => [ 23, 'HP::Copy::CopyFailureException' ],
			'personal_exception4' => [ 67, 'HP::Copy::CopyFailureException' ],
			'personal_exception5' => [ -90, 'HP::Copy::CopyFailureException' ],
			'personal_exception6' => [ -90, 'HP::Copy::CopyFailureException' ],
			'personal_exception7' => [ -254, 'HP::Copy::CopyFailureException' ], };

$exDB->install_exception_types($pe);
is ( $exDB->number_exceptions() == 6, 1);

my $result = $exDB->remove_exception('name', 'personal_exception3');
is ( $result eq TRUE, 1 );
is ( $exDB->number_exceptions() == 5, 1);

$result = $exDB->remove_exception('id', 254);
is ( $result eq TRUE, 1 );
is ( $exDB->number_exceptions() == 4, 1);

$exDB->remove_exception('id', 1);
is ( $exDB->number_exceptions() == 4, 1);

&debug_obj($exDB);