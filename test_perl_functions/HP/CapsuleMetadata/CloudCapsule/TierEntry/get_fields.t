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
  
my $obj = &create_object('c__HP::CapsuleMetadata::CloudCapsule::TierEntry__');
$obj->name('com.hp.csl.test');
$obj->tierid(1);

is ( defined($obj), 1 );

is ( $obj->get_name() eq 'com.hp.csl.test', 1 );
is ( $obj->get_tier() eq 1, 1 );

&debug_obj($obj);