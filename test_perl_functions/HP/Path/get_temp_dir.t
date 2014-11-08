#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::Os');
    use_ok('HP::Path');
  }

my $default_result = &get_temp_dir();
is ( defined($default_result), 1 );

my $tempdir = &MakeTempDir('TEMPDIR');
&set_temp_dir("$tempdir");
my $result = &get_temp_dir('standard');
is ( $result ne $default_result, 1 );

rmtree("$tempdir");
