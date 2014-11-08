#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
  }

is ( TRUE eq '1', 1 );  
is ( FALSE eq '0', 1 );
is ( PASS eq '0', 1 );
is ( FAIL eq '1', 1 );
