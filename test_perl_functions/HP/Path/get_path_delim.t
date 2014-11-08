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
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
    use_ok('HP::Path');
  }

my $result = &get_path_delim();
my $expected_result;

if ( &os_is_windows_native() eq TRUE ) {
  $expected_result = ';';
} else {
  $expected_result = ':';
}

is ( $result eq $expected_result, 1 );
