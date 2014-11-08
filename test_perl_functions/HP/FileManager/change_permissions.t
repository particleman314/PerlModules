#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More tests => 6;

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('File::Spec');
    use_ok('HP::Os');
    use_ok('HP::FileManager');
  }

my $permissions = 777;
my $tempdir     = &MakeTempDir("PERMISSIONS");
my $dirsep      = &get_dir_sep();

my $directory = "$tempdir".${dirsep}."testdirectory";
mkdir ("$directory", 0777);
is ( &does_directory_exist("$directory") eq TRUE, 1 );
rmtree("$tempdir");
