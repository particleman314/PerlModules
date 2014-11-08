#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::ProviderList__');
is ( defined($obj), 1 );

my $xmlfile = "$FindBin::Bin/../SettingsFiles/sample_provider_mapping.xml";
$obj->readfile("$xmlfile");

my $result = $obj->find_provider();
is ( (not defined($result)), 1 );

$result = $obj->find_provider({});
is ( (not defined($result)), 1 );

$result = $obj->find_provider({'lookup' => 'name'});
is ( (not defined($result)), 1 );

$result = $obj->find_provider({'value' => 'F5-BigIP'});
is ( defined($result), 1 );

$result = $obj->find_provider({'lookup' => 'name', 'value' => 'F5-BigIP'});
is ( defined($result), 1 );

$result = $obj->find_provider({'lookup' => 'value', 'value' => 'com.hp.csl.dma'});
is ( defined($result), 1 );

&debug_obj($result);