#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::Support::Module::Constants");
  }

is ( COLON_OPERATOR eq '::', 1 );
is ( PERLMOD_EXTENSION eq '.pm', 1 );

