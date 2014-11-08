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

my $pe = { 'personal_exception' => [ 4, 'HP::Blah' ] };
$exDB->add_exception_type('personal_exception', $pe->{'personal_exception'});
$exDB->add_exception_type($pe);

is ( $exDB->number_exceptions() == 1, 1);

&debug_obj($exDB);