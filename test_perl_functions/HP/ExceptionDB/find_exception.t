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
	use_ok('HP::Array::Constants');
  }

my $exDB = &create_instance('c__HP::ExceptionDB__');
is ( $exDB->number_exceptions() == 0, 1);

my $pe1 = { 'personal_exception1' => [ 4, 'HP::Blah' ] };
my $pe2 = { 'personal_exception2' => [ 5, 'HP::Blah' ] };
my $pe3 = { 'personal_exception3' => [ 23, 'HP::Blah' ] };
my $pe4 = { 'personal_exception4' => [ 67, 'HP::Blah' ] };
my $pe5 = { 'personal_exception5' => [ -90, 'HP::Blah' ] };
my $pe6 = { 'personal_exception6' => [ -254, 'HP::Blah' ] };

$exDB->add_exception_type($pe1);
$exDB->add_exception_type($pe2);
$exDB->add_exception_type($pe3);
$exDB->add_exception_type($pe4);
$exDB->add_exception_type($pe5);
$exDB->add_exception_type($pe6);

is ( $exDB->number_exceptions() == 6, 1);

my $result = $exDB->find_exception_index('id', 23);
is ( $result eq 2, 1 );

$result = $exDB->find_exception_index('name', 'personal_exception3');
is ( $result eq 2, 1 );

$result = $exDB->find_exception_index('id', 90);
is ( $result eq 4, 1 );

$result = $exDB->find_exception_index('id', 1);
is ( $result eq NOT_FOUND, 1 );

$result = $exDB->find_exception_index('method', 'HP::Blah');
is ( $result eq 0, 1 );

$result = $exDB->find_exception_index('method', 'HP::BooHoo');
is ( $result eq NOT_FOUND, 1 );

&debug_obj($exDB);