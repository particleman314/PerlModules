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

my $result = &eat_quotations();
is ( (not defined($result)), 1 );

$result = &eat_quotations('"This is a quoted string"');
is ( defined($result), 1 );
is ( $result eq 'This is a quoted string', 1 );

$result = &eat_quotations('This is a unquoted string');
is ( defined($result), 1 );
is ( $result eq 'This is a unquoted string', 1 );