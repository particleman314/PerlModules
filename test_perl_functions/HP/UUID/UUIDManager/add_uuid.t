#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	#use_ok('HP::UUID::Constants');
  }

my $uuidDB = &create_instance('c__HP::UUID::UUIDManager__');
is ( $uuidDB->number_uuids() == 0, 1);

my ($result, $err) = $uuidDB->add_uuid();
is ( $result eq FALSE, 1 );
&debug_obj($err);

($result, $err) = $uuidDB->add_uuid('1234');
is ( $result eq FALSE, 1 );
&debug_obj($err);

($result, $err) = $uuidDB->add_uuid('00000000-0000-0000-0000-000000000000');
is ( $result eq FALSE, 1 );
&debug_obj($err);

($result, $err) = $uuidDB->add_uuid('12345678-9101-1121-3141-516171819202');
is ( $result eq FALSE, 1 );
&debug_obj($err);

my $uuidentry = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry->uuid('12345678-9101-1121-3141-516171819202');
($result, $err) = $uuidDB->add_uuid($uuidentry);
is ( $result eq FALSE, 1 );
&debug_obj($err);

$uuidentry->filename('ABC\XYZ');
($result, $err) = $uuidDB->add_uuid($uuidentry);
is ( $result eq TRUE, 1 );

my $uuidentry2 = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry2->uuid('11111111-1111-1111-1111-516171819202');
$uuidentry2->filename('ABC\XYZ2');
($result, $err) = $uuidDB->add_uuid($uuidentry2);
is ( $result eq TRUE, 1 );
&debug_obj($err);

&debug_obj($uuidDB);


