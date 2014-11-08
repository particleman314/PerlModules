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
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
    use_ok('HP::String');
    use_ok('HP::Path');
  }

my $test_path = undef;
my $result = &get_resolved_path();
is ( defined($result) == 0, 1 );

$test_path = '';
$result = &get_resolved_path($test_path);
is ( defined($result), 1 );
is ( $result eq '', 1 );

my $testdir = &MakeTempDir('RESOLVED_PATH');
my $deepdir = File::Spec->catfile("$testdir", 'xyz','abc');
$deepdir = &lowercase_first("$deepdir") if ( &os_is_windows() );
mkpath ("$deepdir");

$result = &get_resolved_path("$deepdir");
is ( defined($result), 1 );
is ( $result eq $deepdir, 1 );

$result = &get_resolved_path(File::Spec->catfile('.', 'RESOLVED_PATH', 'xyz', 'abc'));
is ( defined($result), 1 );
is ( $result eq $deepdir, 1 );

rmtree("$testdir");
