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

my $result = &uppercase_all();
is ( defined($result), 1 );
is ( $result eq '', 1 );

$result = &uppercase_all('This is a test');
is ( defined($result), 1 );
is ( $result eq 'THIS IS A TEST', 1 );

$result = &uppercase_all('this is a test with numbers 123456789');
is ( defined($result), 1 );
is ( $result eq 'THIS IS A TEST WITH NUMBERS 123456789', 1 );
