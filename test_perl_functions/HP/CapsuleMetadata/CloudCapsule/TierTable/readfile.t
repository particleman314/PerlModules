#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Path');
  }
  
my $obj = &create_object('c__HP::CapsuleMetadata::CloudCapsule::TierTable__');
is ( defined($obj), 1 );

my $testfile = &path_to_unix(&normalize_path("$FindBin::Bin/../../../SettingsFiles/sample_tier_table.xml"));
$obj->readfile("$testfile");

is ( $obj->number_elements() > 1, 1 );

&debug_obj($obj);