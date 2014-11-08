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

my $result = $driveDB->__run_drive_process();
is ( $result eq FAIL, 1 );

my $jobout = undef;

($result, $jobout) = $driveDB->__run_drive_process(undef, [], TRUE );
is ( $result eq FAIL, 1 );
is ( (not defined($jobout)), 1 );

($result, $jobout) = $driveDB->__run_drive_process('net', ['use'], TRUE );
is ( $result eq PASS, 1 );
is ( defined($jobout), 1 );

($result, $jobout) = $driveDB->__run_drive_process('subst', [], TRUE );
is ( $result eq PASS, 1 );
is ( defined($jobout), 1 );

&debug_obj($result);
&debug_obj($driveDB);
&shutdownDBs();