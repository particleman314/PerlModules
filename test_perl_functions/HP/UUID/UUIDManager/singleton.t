#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Utilities');
  }

my $uuidDB = &create_instance('c__HP::UUID::UUIDManager__');
is ( $uuidDB->number_uuids() == 0, 1);

my $uuidDB2 = &create_instance('c__HP::UUID::UUIDManager__');

my $result = $uuidDB->equals($uuidDB2);
is ( $result eq TRUE, 1);
is ( &get_memory_address($uuidDB) eq &get_memory_address($uuidDB2), 1 );
&debug_obj($uuidDB2);


