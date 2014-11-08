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

my $result = &lowercase_all();
is ( defined($result), 1 );
is ( $result eq '', 1 );

$result = &lowercase_all('This is a test');
is ( defined($result), 1 );
is ( $result eq 'this is a test', 1 );

$result = &lowercase_all('THIS IS A TEST WITH NUMBERS 123456789');
is ( defined($result), 1 );
is ( $result eq 'this is a test with numbers 123456789', 1 );

$result = &lowercase_all(' ');
is ( defined($result), 1 );
is ( $result eq ' ', 1 );
