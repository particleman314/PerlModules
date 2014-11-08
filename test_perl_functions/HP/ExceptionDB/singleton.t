#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Utilities');
  }

my $exDB = &create_instance('c__HP::ExceptionDB__');
is ( $exDB->number_exceptions() == 0, 1);

my $exDB2 = &create_instance('c__HP::ExceptionDB__');

my $result = $exDB->equals($exDB2);
is ( $result eq TRUE, 1);
is ( &get_memory_address($exDB) eq &get_memory_address($exDB2), 1 );
&debug_obj($exDB2);


