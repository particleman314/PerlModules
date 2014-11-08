#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Drive::MapperDB::Constants');
	use_ok('HP::Os');
	use_ok('HP::DBContainer');
	use_ok('HP::String');
  }

&createDBs();
my $driveDB = &getDB('drive');
is ( defined($driveDB), 1 );

# This will be put back once we are finished...
my $current_map  = $driveDB->enumerate();
my $known_drives = $driveDB->get_drives();

my $result = $driveDB->clear_drive();
is ( defined($result), 1 );
is ( $result eq DRIVE_CLEARED, 1 );

&debug_obj($driveDB);
&debug_obj($known_drives);

foreach ( @{$known_drives} ) {
  diag("Checking drive << $_ >>");
  next if ( &lowercase_all($_) eq 'c:' );
  diag("Clearing drive << $_ >>");
  $result = $driveDB->clear_drive("$_");
  is ( defined($result), 1 );
  is ( ($result eq DRIVE_CLEARED) || ($result eq PASS), 1 );
  &debug_obj($result);
}

&debug_obj($driveDB);

$driveDB->install_map($current_map);

&debug_obj($driveDB);
$current_map = $driveDB->enumerate();
&debug_obj($current_map);
&shutdownDBs();