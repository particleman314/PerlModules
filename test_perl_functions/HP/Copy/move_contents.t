#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
      require_ok('HP/TestTools.pl');
      use_ok("File::Path");
      use_ok("HP::Os");
      use_ok("HP::Support::Os");
      use_ok("HP::Array::Tools");
      use_ok("HP::Path");
      use_ok("HP::Copy");
  }

  exit 0;
my $exe_rsync = &which('rsync');
if ( not defined($exe_rsync) ) {
  if ( not &os_is_windows_native() ) {
    $ENV{'USE_NON_RSYNC_METHOD'} = 1;
  }
}

my $tempdir = &MakeTempDir('COPY');

# Make two directories and two files.
my $dir1 = &join_path("$tempdir", "copydir1");
my $dir2 = &join_path("$tempdir", "copydir2");
my $dir3 = &join_path("$tempdir", "copydir3");

my $file1 = &join_path("$tempdir", "file1");
my $file2 = &join_path("$tempdir", "file2");

if ( not -d "$dir1" ) { mkpath("$dir1",0, 0777); }
if ( not -d "$dir2" ) { mkpath("$dir2",0, 0777); }

if ( not -f "$file1" ) { &touch_file("$file1"); }
if ( not -f "$file2" ) { &touch_file("$file2"); }

# Trial 1 -- copy file1 to dir1
diag("File -- $file1\nDirectory -- $dir1");
&copy_with_rsync("$file1","$dir1");
is (( -e "$dir1/file1" ),1);
unlink("$dir1/file1");

&copy_with_rsync("$file1","$dir1/");
is (( -e "$dir1/file1" ),1);
unlink("$dir1/file1");

# Trial 2 -- copy dir1 to dir2 (literal)
# NO slashes PRESERVE DIRECTORY STRUCTURE INCLUDING TOPLEVEL
# Behaviour is slightly different from windows and unix
&copy_with_rsync("$file1","$dir1");
&copy_with_rsync("$dir1","$dir2");

is (( -d "$dir2/copydir1" ),1);
is (( not -e "$dir2/file1" ),1);

rmtree("$dir2/copydir1");

# Trial 3 -- copy dir1 to dir2 (contents)
# IF sender HAS SLASH, then contents are sent
&copy_with_rsync("$dir1/","$dir2");

is (( not -d "$dir2/copydir1" ),1);
is (( -e "$dir2/file1" ),1);

unlink("$dir2/file1");

# Trial 4 -- copy dir1 to dir2 (contents with receiver having slash)
# IF sender HAS SLASH, then contents are sent
&copy_with_rsync("$dir1/","$dir2/");

is (( not -d "$dir2/copydir1" ),1);
is (( -e "$dir2/file1" ),1);

unlink("$dir2/file1");

# Trial 5 -- copy dir1 to dir3 (need to make dir3)
# IF sender HAS SLASH, then contents are sent
&copy_with_rsync("$dir1/","$dir3");

is (( -d "$dir3" ),1);
is (( -e "$dir3/file1" ),1);

rmtree("$dir3");

# Trial 6 -- copy dir1 to dir3 (need to make dir3 with receiver having slash)
# IF sender HAS SLASH, then contents are sent
&copy_with_rsync("$dir1/","$dir3/");

is (( -d "$dir3" ),1);
is (( -e "$dir3/file1" ),1);

rmtree("$dir3");

# Trial 7 -- copy dir1 to dir3 (no slashes on dir1 or dir3)
&copy_with_rsync("$dir1","$dir3");

is (( -d "$dir3/copydir1" ),1);
is (( not -e "$dir3/file1" ),1);

rmtree("$dir3/copydir1");

# Trial 8 -- copy dir1 to dir3 (slashes on dir3 only when need to make)
&copy_with_rsync("$dir1","$dir3/");

is (( -d "$dir3/copydir1" ),1);
is (( not -e "$dir3/file1" ),1);

rmtree("$tempdir");
if ( -d "$tempdir" ) {
  rmtree("$tempdir");
}
