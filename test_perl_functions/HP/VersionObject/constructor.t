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
    use_ok('HP::VersionObject');
  }

my $version = '1.2.3';
my $vobj = HP::VersionObject->new({'version' => $version});
is ( defined($vobj), 1 );

is ( $vobj->get_version() eq $version, 1 );
is ( $vobj->get_version_delimiter() eq '.', 1 );

diag("Version --> " .$vobj->get_version(). "\n");
&debug_obj($vobj);


