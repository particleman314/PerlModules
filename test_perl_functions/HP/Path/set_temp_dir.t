#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
    use_ok('HP::Path');
  }

my $baseline = &get_temp_dir();
&set_temp_dir();

my $result = &get_temp_dir();
is ( $result eq $baseline, 1 );

my $testdir = &MakeTempDir('TEMPDIR');

&set_temp_dir("$testdir");
$result = &get_temp_dir();
is ( $result ne $baseline, 1 );

&set_temp_dir("$baseline");
my $testfile = File::Spec->catfile("$testdir", 'xyz.log');
my $strobj = &create_object('c__HP::Stream::IO::Output__');

$strobj->touch_file("$testfile");

&set_temp_dir("$testfile");
$result = &get_temp_dir();
is ( $result eq $baseline, 1 );

rmtree("$testdir");
