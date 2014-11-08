#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Timestamp');
  }
  
my $obj = &create_object('c__HP::CapsuleMetadata::CloudCapsule::BuildInfo__');
my $time = &get_formatted_time();
my $revision = 12345;
my $buildno  = 42;

is ( defined($obj), 1 );

$obj->build_date($time);
$obj->svn_revision($revision);
$obj->build_number($buildno);

is ( $obj->svn_revision() eq $revision, 1 );

&debug_obj($obj);