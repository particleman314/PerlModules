#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Exception::Tools');
	use_ok('HP::Exception::Constants');
	use_ok('HP::DBContainer');
  }

&createDBs();
my $result = &add_exception_mapping();
is ( $result eq NO_EXCEPTION_INSTALLED, 1 );
is ( $result eq FALSE, 1 );

$result = &add_exception_mapping(undef, undef, undef);
is ( $result eq NO_EXCEPTION_INSTALLED, 1 );

$result = &add_exception_mapping('FICITIOUS_EXCEPTION', -3, undef);
is ( $result eq NO_EXCEPTION_INSTALLED, 1 );

$result = &add_exception_mapping('FICITIOUS_EXCEPTION', 57632, undef);
is ( $result eq NO_EXCEPTION_INSTALLED, 1 );

$result = &add_exception_mapping('FICITIOUS_EXCEPTION', 57632, 'HP::Copy::Exception');
is ( $result eq NO_EXCEPTION_INSTALLED, 1 );

$result = &add_exception_mapping('FICITIOUS_EXCEPTION', 45, 'c__HP::Copy::Exception__');
is ( $result eq EXCEPTION_INSTALLED, 1 );
is ( $result eq TRUE, 1 );

$result = &add_exception_mapping('FICITIOUS2_EXCEPTION', 45, 'c__HP::Copy::Exception__');
is ( $result eq NO_EXCEPTION_INSTALLED, 1 );

$result = &add_exception_mapping('FICITIOUS_EXCEPTION', 49, 'c__HP::Copy::Exception__');
is ( $result eq NO_EXCEPTION_INSTALLED, 1 );

&show_exception_map();
&shutdownDBs();