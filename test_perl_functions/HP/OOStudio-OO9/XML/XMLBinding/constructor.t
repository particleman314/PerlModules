#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::OOStudio::OO9::XMLBinding');
	use_ok('HP::Utilities');
  }

my $ooobj1 = HP::OOStudio::OO9::XMLBinding->new();
is ( defined($ooobj1), 1 );

&debug_obj($ooobj1);


