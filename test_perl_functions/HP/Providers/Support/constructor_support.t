#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::SupportMatrix');
	use_ok('HP::Utilities');
  }

my $smobj = HP::SupportMatrix->new();
is ( defined($smobj), 1 );

&debug_obj($smobj);
