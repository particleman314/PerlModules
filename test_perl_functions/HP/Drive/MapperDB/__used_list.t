#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Os');
	use_ok('HP::DBContainer');
  }

&createDBs();
my $driveDB = &getDB('drive');
is ( defined($driveDB), 1 );

my $result = $driveDB->__used_list();
is ( ref($result) =~ m/hash/i, 1 );

if ( &os_is_windows() eq TRUE ) {
  is ( scalar(keys(%{$result})) >= 1, 1 );
}

&debug_obj($result);
&debug_obj($driveDB);
&shutdownDBs();