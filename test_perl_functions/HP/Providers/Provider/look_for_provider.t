#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::CheckLib');
  }
  
my $gdobj = &create_object('c__HP::CSL::DAO::GlobalData__');
my $gsf = "$FindBin::Bin/../../SettingsFiles/global_settings_testfile.xml";
$gdobj->readfile("$gsf");

my $obj = &create_object('c__HP::Providers::Provider__');
is ( defined($obj), 1 );

$obj->hptype('internal');
$obj->providers($gdobj->get_provider_list()->internal()->providers);

my $result = $obj->look_for_provider();
is ( (not defined($result)), 1 );

$result = $obj->look_for_provider('HP-DMA-NO_EXIST');
is ( $result->is_empty() eq TRUE , 1 );

$result = $obj->look_for_provider('HP-3PAR');
is ( defined($result), 1 );
is ( defined($result->get_element(0)), 1 );

$result = $obj->look_for_provider('HP-NA');
is ( defined($result), 1 );
my $item = $result->get_element(0);
is ( defined($item), 1 );

is ( &is_type($item, 'HP::Providers::Common') eq TRUE, 1 );
is ( $item->name() eq 'HP-Network Automation', 1 );

$result = $obj->look_for_provider('MOE Compute');
is ( defined($result), 1 );
$item = $result->get_element(0);
is ( defined($item), 1 );

is ( &is_type($item, 'HP::Providers::Common') eq TRUE, 1 );
is ( $item->name() eq 'HP-Matrix Operating Environment', 1 );
is ( $item->nickname() eq 'HP-MOE', 1 );

$result = $obj->look_for_provider('com.hp.csl.cloudos');
is ( defined($result), 1 );
$item = $result->get_element(0);
is ( defined($item), 1 );

is ( &is_type($item, 'HP::Providers::Common') eq TRUE, 1 );
is ( $item->name() eq 'HP-CloudOS', 1 );
is ( ( not defined($item->nickname()) ), 1 );

$result = $obj->look_for_provider({'lookup' => 'nickname', 'value' => 'HP-NA'});
is ( defined($result), 1 );
$item = $result->get_element(0);
is ( defined($item), 1 );

is ( &is_type($item, 'HP::Providers::Common') eq TRUE, 1 );
is ( $item->name() eq 'HP-Network Automation', 1 );

&debug_obj($obj);