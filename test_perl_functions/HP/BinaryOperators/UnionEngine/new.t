#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::BinaryOperator");
	use_ok("HP::BinaryOperators::UnionEngine");
  }

my $obj = HP::BinaryOperators::UnionEngine->new();
is( defined($obj) == 1, 1);
is( ref($obj) eq 'HP::BinaryOperators::UnionEngine', 1);