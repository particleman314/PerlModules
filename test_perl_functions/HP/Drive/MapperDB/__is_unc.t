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

my $result = $driveDB->__is_unc('C:/Users');
is ( $result eq FALSE, 1 );

$result = $driveDB->__is_unc('//network/path');
is ( $result eq TRUE, 1 );

$result = $driveDB->__is_unc();
is ( $result eq FALSE, 1 );

&debug_obj($driveDB);
&shutdownDBs();