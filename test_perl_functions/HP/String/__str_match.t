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

my $result = &HP::String::__str_match();
is ( defined($result), 1 );
is ( $result eq FALSE, 1 );

$result = &HP::String::__str_match('This is a test');
is ( defined($result), 1 );
is ( $result eq FALSE, 1 );

$result = &HP::String::__str_match('This is a test', 'test');
is ( defined($result), 1 );
is ( $result eq TRUE, 1 );

$result = &HP::String::__str_match('This is a test', 'weather');
is ( defined($result), 1 );
is ( $result eq FALSE, 1 );
