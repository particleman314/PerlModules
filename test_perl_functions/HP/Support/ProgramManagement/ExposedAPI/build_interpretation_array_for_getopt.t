#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok('HP::Constants');
	use_ok('HP::Support::ProgramManagement');
  }

my $result = &initial_setup();

&debug_obj($result);