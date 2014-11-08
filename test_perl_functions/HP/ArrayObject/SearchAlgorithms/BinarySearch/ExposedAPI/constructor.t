#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Array::SearchAlgorithms::BinarySearch');
  }
  
my $srchobj = HP::Array::SearchAlgorithms::BinarySearch->new();
is ( defined($srchobj), 1 );
&debug_obj($srchobj);