#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::DBContainer');
  }

&createDBs();
my $driveDB = &getDB('drive');
is ( defined($driveDB), 1 );

my $result = $driveDB->__parse_subst_output();
my $num_keys = scalar(keys(%{$result}));
is ( $num_keys eq 0, 1 );

&debug_obj($result);
&debug_obj($driveDB);
&shutdownDBs();