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

my $version = '1.2.3';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );
is ( $vobj->get_version() eq $version, 1 );
is ( $vobj->comparison() eq EQUALS->{'representation'}, 1 );

my $version2 = '1.02.4';
my $vobj2 = &create_object('c__HP::VersionObject__');
$vobj2->set_version($version2);
is ( defined($vobj2), 1 );
is ( $vobj2->get_version() eq $version2, 1 );

my $result = $vobj->compare($vobj2);
is ( defined($result), 1 );
is ( $result eq FALSE, 1 );

$vobj2->set_version($version);
$result = $vobj->compare($vobj2);
is ( $result eq TRUE, 1 );

my $version3 = '1.02.3';
my $vobj3 = &create_object('c__HP::VersionObject__');
$vobj3->set_version($version3);
is ( defined($vobj3), 1 );
is ( $vobj3->get_version() eq $version3, 1 );

$result = $vobj->compare($vobj3, TRUE);
is ( $result eq FALSE, 1 );

&debug_obj($vobj);
&debug_obj($vobj2);


