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
    use_ok('HP::String');
  }

my $result = &chomp_r();
is ( (not defined($result)), 1 );

$result = &chomp_r('hello');
is ( defined($result), 1 );
is ( $result eq 'hello', 1 );

$result = &chomp_r("hello\n");
is ( defined($result), 1 );
is ( $result eq 'hello', 1 );

$result = &chomp_r("hello\r\n");
is ( defined($result), 1 );
is ( $result eq 'hello', 1 );

$result = &chomp_r(["hello\n", "world\n"]);
is ( defined($result), 1 );
is ( $result->[0] eq 'hello', 1 );
is ( $result->[1] eq 'world', 1 );

&debug_obj($result);