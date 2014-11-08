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
	use_ok('HP::String');
	use_ok('HP::Path');
  }

&createDBs();
my $driveDB = &getDB('drive');
is ( defined($driveDB), 1 );

my $result = $driveDB->collapse_drivepath();
is ( (not defined($result)), 1 );

if ( &lowercase_all(&get_hostname()) eq 'klusmani2' ) {
  my $current_map = $driveDB->enumerate();
  $driveDB->release_drives();

  my $dl = $driveDB->set_drive('c:/Users/klusmani/HP Software/CSL Source/branches/development/fossil-proxy');
  is ( $dl eq 'z:', 1 );

  my $result = $driveDB->expand_drivepath();
  is ( (not defined($result)), 1 );

  if ( &lowercase_all(&get_hostname()) eq 'klusmani2' ) {
    $result = $driveDB->expand_drivepath('z:');
    is ( defined($result), 1 );
    is ( $result eq &path_to_win('c:/Users/klusmani/HP Software/CSL Source/branches/development/fossil-proxy'), 1 );
  
    $result = $driveDB->expand_drivepath('z:\OOFlows');
    is ( defined($result), 1 );
    is ( $result eq &path_to_win('c:/Users/klusmani/HP Software/CSL Source/branches/development/fossil-proxy/OOFlows'), 1 );

    &debug_obj($result);
  }

  $driveDB->install_map($current_map);
}

&debug_obj($driveDB);
&shutdownDBs();