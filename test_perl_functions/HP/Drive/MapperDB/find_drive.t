#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::DBContainer');
	use_ok('HP::Os');
	use_ok('HP::String');
  }

&createDBs();
my $driveDB = &getDB('drive');
is ( defined($driveDB), 1 );

my $result = $driveDB->find_drive();
is ( (not defined($result)), 1 );

$result = $driveDB->find_drive('c:/Users/DoesNotExist');
is ( (not defined($result)), 1 );

if ( &lowercase_all(&get_hostname()) eq 'klusmani2' ) {
  my $current_map = $driveDB->enumerate();
  $driveDB->release_drives();

  my $dl = $driveDB->set_drive('c:/Users/klusmani/HP Software/CSL Source/branches/development/fossil-proxy');
  is ( $dl eq 'z:', 1 );

  $result = $driveDB->find_drive('c:/Users/klusmani/HP Software/CSL Source/branches/development/fossil-proxy');
  is ( defined($result), 1 );
  is ( $result eq 'z:', 1 );
  
  $driveDB->install_map($current_map);
}

&debug_obj($driveDB);
&shutdownDBs();