#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok("HP::Constants");
    use_ok("HP::CheckLib");
  }

my $function_id = 'function_exists';
my $does_func_exist = &function_exists();
is ( $does_func_exist eq FALSE, 1);

$does_func_exist = &function_exists($function_id);
is ( $does_func_exist eq TRUE, 1);

$does_func_exist = &function_exists('HP::CheckLib',$function_id);
is ( $does_func_exist eq TRUE, 1 );

$does_func_exist = &function_exists('HP::CheckLib', 'xyz');
is ( $does_func_exist eq FALSE, 1 );