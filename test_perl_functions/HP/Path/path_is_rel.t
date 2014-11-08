#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::Path');
  }

my $result = &path_is_rel();
is ( $result, 0 );

my $testdir = &MakeTempDir('RELPATH');
$result = &path_is_rel("$testdir");
is ( $result, 0 );

$result = &path_is_rel(File::Spec->catfile('.', 'RELPATH'));
is ( $result, 1 );

$result = &path_is_rel(File::Spec->catfile("$testdir", 'xyz'));
is ( $result, 0 );

rmtree("$testdir");
