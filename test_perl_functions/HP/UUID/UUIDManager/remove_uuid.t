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

my $uuidentry = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry->uuid('12345678-9101-1121-3141-516171819202');
$uuidentry->filename('ABC\XYZ');
($result, $err) = $uuidDB->add_uuid($uuidentry);
is ( $result eq TRUE, 1 );

my $uuidentry2 = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry2->uuid('11111111-1111-1111-1111-516171819202');
$uuidentry2->filename('ABC\XYZ2');
($result, $err) = $uuidDB->add_uuid($uuidentry2);
is ( $result eq TRUE, 1 );

is ( $uuidDB->number_uuids() eq 2, 1 );
&debug_obj($uuidDB);

$uuidDB->remove_uuid($uuidentry->uuid());
is ( $uuidDB->number_uuids() eq 1, 1 );

&debug_obj($uuidDB);


