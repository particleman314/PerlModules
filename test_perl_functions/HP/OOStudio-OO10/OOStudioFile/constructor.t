#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::OOStudio::OOStudioFile');
	use_ok('HP::Utilities');
  }

my $ooobj1 = HP::OOStudio::OOStudioFile->new();
is ( defined($ooobj1), 1 );

&debug_obj($ooobj1);


