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
	use_ok('HP::Version::Constants');
  }

my $version = '10.10.01';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );

&debug_obj($vobj);

my $result = $vobj->prepare_xml();
diag("\n". $result ."\n");

$vobj->set_style();
my $result2 = $vobj->prepare_xml();
diag("\n". $result2 ."\n");
is ( $result eq $result2, 1 );

$vobj->set_style(4);
$result2 = $vobj->prepare_xml();
diag("\n". $result2 ."\n");
is ( $result eq $result2, 1 );

$vobj->set_style(XMLATTR);
$result2 = $vobj->prepare_xml();
diag("\n". $result2 ."\n");
is ( $result ne $result2, 1 );

&debug_obj($vobj);

