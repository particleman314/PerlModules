#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Array::SearchAlgorithms::LinearSearch');
  }
  
my $srchobj = HP::Array::SearchAlgorithms::LinearSearch->new();
is ( defined($srchobj), 1 );
&debug_obj($srchobj);