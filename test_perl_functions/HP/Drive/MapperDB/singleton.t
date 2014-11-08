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

my $driveDB = &create_instance('c__HP::Drive::MapperDB__');
is ( defined($driveDB), 1 );

my $driveDB2 = &create_instance('c__HP::Drive::MapperDB__');
is ( defined($driveDB2), 1 );

my $result = $driveDB->equals($driveDB2);
is ( $result eq TRUE, 1);
is ( &get_memory_address($driveDB) eq &get_memory_address($driveDB2), 1 );

&debug_obj($driveDB2);