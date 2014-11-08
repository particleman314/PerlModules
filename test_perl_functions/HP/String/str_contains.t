#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Base');
    use_ok('HP::String');
  }

my $result = &str_contains();
is ( $result eq FALSE, 1 );

$result = &str_contains('This is my message');
is ( $result eq FALSE, 1 );

$result = &str_contains('This is my message', [ 'This' ]);
is ( $result eq TRUE, 1 );

$result = &str_contains('This is my message', [ 'noway' ]);
is ( $result eq FALSE, 1 );

$result = &str_contains('This is my message', [ 'noway', 'message' ]);
is ( $result eq TRUE, 1 );

$result = &str_contains('dir',[ ' ' ]);
is ( $result eq FALSE, 1 );