#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('Cwd');
    use_ok('File::Path');
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
    use_ok('HP::String');
    use_ok('HP::Path');
	use_ok('HP::Path::Constants');
  }

my $testdir  = &getcwd();
my $testdir2 = &HP::Path::__flip_slashes("$testdir", PATH_BACKWARD, PATH_FORWARD);
is ($testdir eq $testdir2, 1);

$testdir = "/abc/def/ghi";
my $expected = "/abc/def/ghi";
my $answer = &HP::Path::__flip_slashes("$testdir", PATH_BACKWARD, PATH_FORWARD);
is ( $answer eq $expected, 1);

$expected = '\abc\def\ghi';
$answer = &HP::Path::__flip_slashes("$testdir", PATH_FORWARD, PATH_BACKWARD);
is ( $answer eq $expected, 1);

$testdir = '\abc\def\ghi';
$expected = "/abc/def/ghi";
$answer = &HP::Path::__flip_slashes("$testdir", PATH_BACKWARD, PATH_FORWARD);
is ( $answer eq $expected, 1);

$testdir = "/abc def/ghi jkl/lmn opq/rs";
$expected = "/abc def/ghi jkl/lmn opq/rs";
$answer = &HP::Path::__flip_slashes("$testdir", PATH_BACKWARD, PATH_FORWARD);
is ( $answer eq $expected, 1);

$testdir = '/abc def/ghi jkl/lmn opq/rs';
$expected = "$testdir";
$answer = &HP::Path::__flip_slashes("$testdir", PATH_BACKWARD, PATH_FORWARD);
is ( $answer eq $expected, 1);
