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
	use_ok('HP::Array::Tools');
  }

&createDBs();
my $driveDB = &getDB('drive');
is ( defined($driveDB), 1 );

# This will be put back once we are finished...
my $current_map = $driveDB->enumerate();
my $current_dls = $driveDB->get_drives();

&debug_obj($driveDB);

if ( &lowercase_all(&get_hostname()) eq 'klusmani2' ) {
  my $first_path = 'c:/Users/klusmani/HP Software';
  my $newdl = $driveDB->set_drive("$first_path");

  my $second_path = 'c:/Users/klusmani/HP Software/CSL Source/tags';
  $newdl = $driveDB->set_drive("$second_path");
  
  my $final_path = 'c:/Users/klusmani/HP Software/CSL Source/branches';
  $newdl = $driveDB->set_drive("$second_path", undef, undef, FALSE);
  &debug_obj($driveDB);
}

$driveDB->release_drives();
$driveDB->install_map($current_map);

my $latest_dls = $driveDB->get_drives();
is ( scalar(@{$latest_dls}) == scalar(@{$current_dls}), 1 );

&debug_obj($driveDB);
&shutdownDBs();