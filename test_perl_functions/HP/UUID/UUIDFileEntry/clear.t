#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::UUID::Constants');
	use_ok('HP::UUID::Tools');
  }

my $obj = &create_object('c__HP::UUID::UUIDFileEntry__');
is ( defined($obj), 1 );

$result = $obj->add({'uuid' => &generate_unique_uuid([], 4), 'filename' => 'XYZ/ABC'});
is ( $result eq TRUE, 1 );
is ( ($obj->uuid() ne ZERO_UUID), 1 );

&debug_obj($obj);
$obj->clear();

is ( ($obj->uuid() eq ZERO_UUID), 1 );
is ( (not defined($obj->filename())), 1 );
&debug_obj($obj);