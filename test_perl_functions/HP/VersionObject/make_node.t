#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
  }

my $version = '10.10.01';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );

my $xmlnode = $vobj->make_node();
diag( "\n". $xmlnode ."\n");

$xmlnode = $vobj->make_node('root_version_name');
diag( "\n". $xmlnode ."\n");

&debug_obj($vobj);


