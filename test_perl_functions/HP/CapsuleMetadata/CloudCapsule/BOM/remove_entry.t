#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOM__');
is ( defined($obj), 1 );

my $bomf = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOMFile__');
is ( defined($bomf), 1 );

$bomf->name('FileXYZ123.jar');
$bomf->version()->set_version('1.01');
$bomf->tag('CP6');

my $bomf2 = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOMFile__');
is ( defined($bomf2), 1 );

$bomf2->name('FileXYZABC.jar');
$bomf2->version()->set_version('2.0.6');
$bomf2->tag('CP6.1');

my $bomf3 = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOMFile__');
is ( defined($bomf3), 1 );

$bomf3->name('QWERTY.jar');
$bomf3->version()->set_version('9.07.003');
$bomf3->tag('CP6');

$obj->add_entry($bomf);
$obj->add_entry($bomf2);
$obj->add_entry($bomf3);

&debug_obj($obj);

my $result = $obj->count();
is ( $result eq 3, 1 );

my $success = $obj->remove_entry();
is ( $success eq FALSE, 1 );
$result = $obj->count();
is ( $result eq 3, 1 );

$success = $obj->remove_entry($bomf);
is ( $success eq TRUE, 1 );
$result = $obj->count();
is ( $result eq 2, 1 );

$success = $obj->has_entry($bomf);
is ( $success eq FALSE, 1 );

&debug_obj($obj);