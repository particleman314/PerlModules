#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	#use_ok('HP::Utilities');
  }

my $uuidDB = &create_instance('c__HP::UUID::UUIDManager__');
is ( $uuidDB->number_uuids() == 0, 1);

$uuidDB->add_jarfile_uuid();
&debug_obj($uuidDB);

my $uuidentry = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry->uuid('12345678-9101-1121-3141-516171819202');
$uuidentry->filename('ABC\XYZ');

my $uuidentry2 = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry2->uuid('11111111-1111-1111-1111-516171819202');
$uuidentry2->filename('ABC\XYZ2');

$uuidDB->add_jarfile_uuid($uuidentry);
$uuidDB->add_jarfile_uuid($uuidentry2);

&debug_obj($uuidDB);


