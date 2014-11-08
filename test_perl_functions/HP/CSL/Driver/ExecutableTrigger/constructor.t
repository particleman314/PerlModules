#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::CSL::Driver::ExecutableTrigger');
  }
  
my $obj = HP::CSL::Driver::ExecutableTrigger->new();
is ( defined($obj), 1 );
&debug_obj($obj);