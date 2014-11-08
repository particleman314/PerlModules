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

$bomf->name('FileXYZ.jar');
$bomf->version()->set_version('1.5.5');
$bomf->tag('CP6');
$bomf->md5sum('deadbeef' x 4);

my $bomf2 = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOMFile__');
is ( defined($bomf2), 1 );

$bomf2->name('FileXYZ2.jar');
$bomf2->version()->set_version('2.0.1');
$bomf2->tag('CP6.1');
$bomf2->md5sum('aabbccdd' x 4);

$obj->add_entry($bomf);
$obj->add_entry($bomf2);

my $result = $obj->find_bom_by_version();
is ( (not defined($result)), 1 );

$result = $obj->find_bom_by_version('1.5.5');
is ( defined($result), 1 );
is ( $result->tag() eq 'CP6', 1 );

my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version('2.0.1');

$result = $obj->find_bom_by_version($vobj);
is ( defined($result), 1 );
is ( $result->tag() eq 'CP6.1', 1 );

&debug_obj($obj);