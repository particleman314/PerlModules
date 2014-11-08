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
$bomf->version()->set_version('2.5.5');
$bomf->tag('CP6');

$obj->push_entry($bomf);

my $result = $obj->count();
is ( $result eq 1, 1 );

&debug_obj($obj);