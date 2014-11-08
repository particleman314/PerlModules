#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
    use_ok('HP::Support::Base');
  }
  
&print_msg("Hello World");
&print_msg("Hello World", INFO);
&print_msg("Hello World", FAILURE, \*STDERR);
