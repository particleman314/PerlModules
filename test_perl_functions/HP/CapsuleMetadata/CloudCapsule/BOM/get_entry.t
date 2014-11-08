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

$obj->add_entry($bomf);
$result = $obj->find_entry($bomf);
is ( defined($result), 1 );

$result = $obj->get_entry($result);
is ( defined($result), 1 );
is ( &is_type($result, 'HP::CapsuleMetadata::CloudCapsule::BOMFile') eq TRUE, 1 );

&debug_obj($result);
&debug_obj($obj);