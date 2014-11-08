#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::UUID::Tools');
  }

my $obj = &create_object('c__HP::UUID::UUIDFileList__');
is ( defined($obj), 1 );
my $temp_uuid = &generate_unique_uuid([], 4);

my $result = $obj->add_file_uuids();
is ( $result eq FALSE, 1 );

$result = $obj->add_file_uuids([]);
is ( $result eq FALSE, 1 );

$result = $obj->add_file_uuids([ [] ]);
is ( $result eq FALSE, 1 );

$obj->add_file_uuids([ [ $temp_uuid ], { "$temp_uuid" => 'AXE'} ]);
is ( scalar(@{$obj->uuid_association()->get_elements()}) == 1, 1);
is ( scalar(@{$obj->uuid_list()->get_elements()}) == scalar(@{$obj->uuid_association()->get_elements()}), 1);

my $previous_uuids = $obj->uuid_list()->get_elements();
my $jfuuid = &generate_unique_uuid($previous_uuids, 4);
$obj->jarfile_uuid($jfuuid);
is ( $obj->jarfile_uuid() eq $jfuuid, 1 );

&debug_obj($obj);