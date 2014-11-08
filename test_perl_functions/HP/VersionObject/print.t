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

my $version = '1.20.300';
my $vobj = &create_object('c__HP::VersionObject__');
$vobj->set_version($version);
is ( defined($vobj), 1 );

is ( $vobj->get_version() eq $version, 1 );
$vobj->print();
$vobj->print(XMLATTR);
&debug_obj($vobj);


