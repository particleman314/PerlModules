#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::String");
  }

my $str1 = 'Hello World';
my $result = &escapify($str1);
is ( $result eq $str1, 1 );

$str1 = 'Hello World!';
$result = &escapify($str1);
is ( $result eq $str1, 1 );

$str1 = 'Hello:World';
$result = &escapify($str1);
is ( length($result) == length($str1) + 1, 1 );

$str1 = 'Hello:Cruel:World';
$result = &escapify($str1);
is ( length($result) == length($str1) + 2, 1 );

$str1 = 'Hello+Cruel+World';
$result = &escapify($str1);
is ( length($result) == length($str1) + 2, 1 );

$str1 = 'Hello|Cruel|World';
$result = &escapify($str1);
is ( $result eq $str1, 1 );

&HP::String::add_escapified_symbol('|');
$result = &escapify($str1);
is ( length($result) == length($str1) + 2, 1 );
