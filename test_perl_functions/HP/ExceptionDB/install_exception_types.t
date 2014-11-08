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

my $pe  = { 'personal_exception1' => [ 4, 'HP::Blah' ],
            'personal_exception2' => [ 5, 'HP::Blah' ],
			'personal_exception3' => [ 23, 'HP::Blah' ],
			'personal_exception4' => [ 67, 'HP::Blah' ],
			'personal_exception5' => [ -90, 'HP::Blah' ],
			'personal_exception6' => [ -90, 'HP::Blah' ],
			'personal_exception7' => [ -254, 'HP::Blah' ], };

my $install_result = $exDB->install_exception_types($pe);

&debug_obj($install_result);

is ( $exDB->number_exceptions() == 6, 1);

my $result = $exDB->has_exception('id', 23);
is ( $result eq TRUE, 1 );

$result = $exDB->has_exception('name', 'personal_exception3');
is ( $result eq TRUE, 1 );

$result = $exDB->has_exception('id', 1);
is ( $result eq FALSE, 1 );

&debug_obj($exDB);