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
  
my $obj = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BOMFile__');
my $filename = 'FileXYZ.zip';
is ( defined($obj), 1 );

$obj->md5sum('01' x 16);
$obj->name($filename);

is ( $obj->name() eq $filename, 1 );

&debug_obj($obj);