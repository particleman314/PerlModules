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

my $wrong_obj = &create_object('c__HP::XMLObject__');

my $bomf = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOMFile__');
is ( defined($bomf), 1 );

$bomf->name('FileXYZ.jar');
$bomf->version()->set_version('1.5.5');
$bomf->tag('CP6');

my $success = $obj->add_entry();
is ( $success eq FALSE, 1 );
is ( $obj->count() eq 0, 1 );
is ( $obj->count() eq scalar(@{$obj->file()->get_elements()}), 1 );

$success = $obj->add_entry($wrong_obj);
is ( $success eq FALSE, 1 );
is ( $obj->count() eq 0, 1 );
is ( $obj->count() eq scalar(@{$obj->file()->get_elements()}), 1 );

$success = $obj->add_entry($bomf);
is ( $success eq TRUE, 1 );
is ( $obj->count() eq 1, 1 );
is ( $obj->count() eq scalar(@{$obj->file()->get_elements()}), 1 );

&debug_obj($obj);