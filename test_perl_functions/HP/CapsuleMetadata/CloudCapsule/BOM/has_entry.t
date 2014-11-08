#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::CheckLib');
  }
  
my $obj = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOM__');
is ( defined($obj), 1 );

my $bomf = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOMFile__');
is ( defined($bomf), 1 );

$bomf->name('FileXYZ.jar');
$bomf->version()->set_version('1.5.5');
$bomf->tag('CP6');

my $bomf2 = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOMFile__');
is ( defined($bomf2), 1 );

$bomf2->name('FileXYZ.jar');
$bomf2->version()->set_version('1.5.6');
$bomf2->tag('CP6.1');

$obj->add_entry($bomf);

$result = $obj->has_entry($bomf);
is ( $result eq TRUE, 1 );

$result = $obj->has_entry();
is ( $result eq FALSE, 1 );

$result = $obj->has_entry($bomf2);
is ( $result eq FALSE, 1 );

&debug_obj($obj);