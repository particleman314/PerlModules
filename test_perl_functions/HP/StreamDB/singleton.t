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

my $strDB = &create_instance('c__HP::StreamDB__');
is ( $strDB->number_streams() == 3, 1);

my $strDB2 = &create_instance('c__HP::StreamDB__');

my $result = $strDB->equals($strDB2);
is ( $result eq TRUE, 1);
is ( &get_memory_address($strDB) eq &get_memory_address($strDB2), 1 );
&debug_obj($strDB2);


