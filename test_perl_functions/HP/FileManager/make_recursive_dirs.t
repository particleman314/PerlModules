#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More tests => 10;

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('File::Spec');
	use_ok('HP::Constants');
    use_ok('HP::FileManager');
  }

my $testdir     = &MakeTempDir('RECURSIVE');
my $directory   = File::Spec->catfile("$testdir",'test_directory');

is ( &does_directory_exist( "$directory" ) eq FALSE, 1 );
rmtree("$directory");

my $result = &make_recursive_dirs();
is ( ( not defined($result) ), 1 );

$result = &make_recursive_dirs("$directory");
is ( &does_directory_exist( "$directory" ) eq TRUE , 1 );
rmtree("$directory");

$directory = File::Spec->catfile("$directory", 'another_level');
is ( &does_directory_exist( "$directory" ) eq FALSE, 1 );
$result = &make_recursive_dirs("$directory");
is ( &does_directory_exist( "$directory" ) eq TRUE, 1 );
rmtree("$directory");

my $permissions = 755;  # read/write/execute
$result = &make_recursive_dirs("$directory", $permissions);
is ( &does_directory_exist( "$directory" ) eq TRUE, 1 );
rmtree("$directory");

rmtree("$testdir");
