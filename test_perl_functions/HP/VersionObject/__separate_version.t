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

my $version = '1.2.3.4000';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );

is ( $vobj->get_version() eq $version, 1 );
my @result = $vobj->__separate_version();

&debug_obj(\@result);

$vobj->set_version('1.1.5-SNAPSHOT');
is ( $vobj->get_version() ne $version, 1 );
@result = $vobj->__separate_version();

&debug_obj(\@result);
