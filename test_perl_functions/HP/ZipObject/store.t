#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('File::Path');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Path');
	use_ok('HP::FileManager');
  }

exit 0;
my $tempdir = &MakeTempDir('ARCHIVE');

my $testdir = &join_path("$tempdir",'Test','Deep','Structure');
my $obj = &create_object('c__HP::ZipObject__');
is (defined($obj) == 1, 1);

&make_recursive_dirs("$testdir");

my $dircontents = &collect_directory_contents("$FindBin::Bin");
$obj->add("$tempdir");

foreach ( @{$dircontents->{'files'}} ) {
  $obj->add(&join_path("$FindBin::Bin", "$_"));
}

foreach ( @{$dircontents->{'directories'}} ) {
  $obj->add(&join_path("$FindBin::Bin", "$_"));
}

is ( $obj->directories()->number_elements() >= 1, 1 );
is ( $obj->files()->number_elements() > 1, 1 );

my $result = $obj->store();
is ( $result eq FALSE, 1);

my $zipfile = &join_path("$FindBin::Bin", 'test.zip');
$result = $obj->store("$zipfile");
is ( &does_file_exist("$zipfile") eq TRUE, 1 );

sleep 2;
rmtree("$tempdir");
&delete("$zipfile");

&debug_obj( $obj );