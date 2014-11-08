#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN {
  require_ok('HP/TestTools.pl');
  use_ok('File::Path');
  use_ok('HP::Constants');
  use_ok('HP::Support::Os');
  use_ok('HP::Path');
  use_ok('HP::Copy');
  use_ok('HP::FileManager');
  use_ok('HP::Support::Object::Tools');
  use_ok('HP::DBContainer');
}

&createDBs();
my $strDB = &getDB('stream');

my $exe_rsync = &which('rsync');
if ( not defined($exe_rsync) ) {
  if ( not &os_is_windows_native() ) {
    $ENV{'USE_NON_RSYNC_METHOD'} = 1;
  }
}

my $tempdir = &MakeTempDir('COPY');

#print STDERR "Temporary work directory : $tempdir\n";

for (my $numFiles = 1; $numFiles <= 30; $numFiles+=3) {
  my $source = &join_path("$tempdir", "copy_with_retry_test.source");
  my $dest   = &join_path("$tempdir", "copy_with_retry_test.dest");

  rmtree("$source", 0, 0) if -e "$source";
  rmtree("$dest", 0, 0)   if -e "$dest";

  ok(not -d "$source");
  mkpath("$source", 0, 0777);

  for (my $fc = 0; $fc < $numFiles; ++$fc) {
    ok( $strDB->touch_file(&join_path("$source", "file$fc\.txt")));
  }

  is(&copy_with_retry("$source/", "$dest", 60),1);
  
  is((-d $dest),1);
  for (my $fc = 0; $fc < $numFiles; ++$fc) {
    is((-e &join_path("$dest", "file$fc\.txt")), 1);
    is((-s &join_path("$dest", "file$fc\.txt")), -s &join_path("$source", "file$fc\.txt"));
  }
  
  ok(rmtree("$dest", 0, 0));
  ok(rmtree("$source", 0, 0));
}
rmtree("$tempdir", 0, 0);
&shutdownDBs();