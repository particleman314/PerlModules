#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::DBContainer');
	use_ok('HP::Drive::MapperDB::Constants');
	use_ok('HP::Os');
  }

&createDBs();
my $driveDB = &getDB('drive');
is ( defined($driveDB), 1 );

my $result = $driveDB->clear_path();
is ( defined($result), 1 );
is ( $result eq DRIVE_CLEARED, 1 );

$result = $driveDB->clear_path('C:\Users\DoesNotExist');
is ( defined($result), 1 );
is ( $result eq DRIVE_CLEARED, 1 );

my $current_map = $driveDB->enumerate();

if ( lc(&get_hostname()) eq 'klusmani2' ) {
  my $path = 'C:\Users\klusmani\HP Software\CSL Cleanup Folder\branches\development\everglades-proxy';
  my $dl   = $driveDB->set_drive("$path");
  
  is ( defined($dl), 1 );
  
  $result = $driveDB->clear_path("$path");
  is ( defined($result), 1 );
  is ( $result eq PASS, 1 );
}

&debug_obj($result);

$driveDB->release_drives();
$driveDB->install_map($current_map);

&debug_obj($driveDB);
&shutdownDBs();