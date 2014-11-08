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

$uuidDB->add_uuid_list();

my $uuidentry = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry->uuid('12345678-9101-1121-3141-516171819202');
$uuidentry->filename('ABC\XYZ');

my $uuidentry2 = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry2->uuid('11111111-1111-1111-1111-516171819202');
$uuidentry2->filename('ABC\XYZ2');

my $uuidentry3 = &create_object('c__HP::UUID::UUIDFileEntry__');
$uuidentry3->uuid('11111111-1111-1111-1111-516171819204');
$uuidentry3->filename('ABC\XYZ3');

my $arrobj = &create_object('c__HP::ArrayObject__');
$arrobj->push_item($uuidentry);
$arrobj->push_item($uuidentry2);
$arrobj->push_item($uuidentry3);

$uuidDB->add_uuid_list($arrobj);

my $result = $uuidDB->find_file_by_uuid($uuidentry2->uuid());
is ( $result eq $uuidentry2->filename(), 1 );

$result = $uuidDB->find_file_by_uuid('12345678-1234-1234-1234-1234567890');
is ( (not defined($result)), 1 );

&debug_obj($uuidDB);


