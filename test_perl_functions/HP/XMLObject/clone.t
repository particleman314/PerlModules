#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('Cwd');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Utilities');
  }

my $xmlobj = &create_object('c__HP::XMLObject__');
is ( defined($xmlobj), 1 );

my $xmlobj2 = &clone_item($xmlobj);

is ( defined($xmlobj2), 1 );
is ( &equal($xmlobj, $xmlobj2) eq TRUE, 1 );
&debug_obj($xmlobj);


