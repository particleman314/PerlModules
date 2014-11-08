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
  }
  
my $obj = &create_object('c__HP::CapsuleMetadata::CloudCapsule::TierTable__');
is ( defined($obj), 1 );

my $entry = &create_object('c__HP::CapsuleMetadata::CloudCapsule::TierEntry__');
$entry->name('com.hp.csl.test');
$entry->tierid(1);

my $cloneable = &get_template_obj($obj->tier_elements());

my $entry2 = $cloneable->clone();
$entry2->name('com.hp.csl.clone');
$entry2->tierid(1);

my $entry3 = $cloneable->clone();
$entry3->name('com.hp.csl.dup');
$entry3->tierid(3);

$obj->add_entry($entry);

$obj->add_entry($entry2);
$obj->add_entry($entry3);

my $test = $cloneable->clone();
$test->name('com.hp.csl.dup');

my $result = $obj->find_tier($test);
is ( defined($result), 1 );
is ( $result eq 3, 1 );

$result = $obj->find_tier('com.hp.csl.clone');
is ( defined($result), 1 );
is ( $result eq 1, 1 );

$result = $obj->find_tier('com.hp.csl.doesnotexist');
is ( (not defined($result)), 1 );

&debug_obj($obj);