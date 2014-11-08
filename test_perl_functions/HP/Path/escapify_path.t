#!/usr/bin/env perl

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
    use_ok('HP::Support::Os');
    use_ok('HP::FileManager');
    use_ok('HP::Path');
  }

my $tempdir  = &MakeTempDir('ESCAPIFY_PATH');
my $testdir  = "$tempdir";
my $testdir2 = &escapify_path("$testdir");

if ( &os_is_windows_native() eq FALSE ) {
  if ( index($testdir,' ') > -1 ) {
    is ($testdir ne $testdir2, 1);
  } else {
    is ($testdir eq $testdir2, 1);
  }
} else {
  is ($testdir eq $testdir2, 1);
}

$testdir .= &join_path("$testdir","abc/xyz uvw");
$testdir2 = &escapify_path("$testdir");

if ( &os_is_windows_native() eq FALSE ) {
  if ( index($testdir,' ') > -1 ) {
    is ($testdir ne $testdir2, 1);
  } else {
    is ($testdir eq $testdir2, 1);
  }
} else {
  is ($testdir eq $testdir2, 1);
}
&delete("$tempdir");