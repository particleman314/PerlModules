#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('Cwd');
    use_ok('File::Path');
	use_ok('HP::Constants');
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
    use_ok('HP::String');
    use_ok('HP::Path');
	use_ok('HP::Path::Constants');
  }

my $test1 = undef;
my $test2 = '';
my $test3 = 'abc';
my $test4 = '/abc';
my $test5 = '\\abc';
my $test6 = 'abc/';
my $test7 = 'abc\\';
my $test8 = '/usr/local/bin';
my $test9 = '\\\\network\\local\\bin';
my $test10 = '/usr/local/bin/';
my $test11 = '\\\\network\\local\\bin\\';

my $answer = &HP::Path::__has_trailing_slash($test1);
is ( $answer eq FALSE, 1 );

$answer = &HP::Path::__has_trailing_slash($test2);
is ( $answer eq FALSE, 1 );

$answer = &HP::Path::__has_trailing_slash($test3);
is ( $answer eq FALSE, 1 );

$answer = &HP::Path::__has_trailing_slash($test4);
is ( $answer eq FALSE, 1 );

$answer = &HP::Path::__has_trailing_slash($test5);
is ( $answer eq FALSE, 1 );

$answer = &HP::Path::__has_trailing_slash($test6);
is ( $answer eq TRUE, 1 );

$answer = &HP::Path::__has_trailing_slash($test7);
is ( $answer eq TRUE, 1 );

$answer = &HP::Path::__has_trailing_slash($test8);
is ( $answer eq FALSE, 1 );

$answer = &HP::Path::__has_trailing_slash($test9);
is ( $answer eq FALSE, 1 );

$answer = &HP::Path::__has_trailing_slash($test10);
is ( $answer eq TRUE, 1 );

$answer = &HP::Path::__has_trailing_slash($test11);
is ( $answer eq TRUE, 1 );
