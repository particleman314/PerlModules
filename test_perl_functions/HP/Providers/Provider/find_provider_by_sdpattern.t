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
$obj->providers($gdobj->get_provider_list()->internal()->providers());

my $result = $obj->find_provider_by_sdpattern();
is ( (not defined($result)), 1 );

$result = $obj->find_provider_by_sdpattern('DoesNotExist');
is ( defined($result), 1 );
is ( $result->is_empty() eq TRUE, 1 );
is ( $result->number_elements() eq 0, 1 );

$result = $obj->find_provider_by_sdpattern('DMA Application Provider WorkFlows');
is ( defined($result), 1 );

&debug_obj($obj);