#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('File::Spec');
	use_ok('HP::Constants');
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
    use_ok('HP::Path');
  }

is(&path_is_same('.', &get_full_path(File::Spec->curdir())), 1);
is(&path_is_same('..', &get_full_path(File::Spec->curdir())), 0);
is(&path_is_same('test/..', &get_full_path(&join_path(File::Spec->curdir(), '..'))), 0);

my $testdir = &MakeTempDir('PATHTEST');
if ( &os_is_linux() eq TRUE ) {
  if (symlink("$testdir", "${testdir}/link")) {
    is(&path_is_same("$testdir", "${testdir}/link"), 1);
  }
}
rmtree("$testdir");
