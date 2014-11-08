#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::BinaryOperator");
	use_ok("HP::BinaryOperators::DifferenceEngine");
  }

my $obj = HP::BinaryOperators::DifferenceEngine->new();
is( defined($obj) == 1, 1);
is( ref($obj) eq 'HP::BinaryOperators::DifferenceEngine', 1);

my @a1 = ( 1 .. 5 );
my @a2 = ( 3 .. 7 );

my $result = $obj->execute_function(\@a1, \@a2);
is( defined($result) == 1, 1);
is( scalar(@{$result}) == 4, 1);

my @a = ( 1, 2, 6, 7 );
for ( my $loop = 0; $loop < scalar(@a); ++$loop ) {
  is( $result->[$loop] eq $a[$loop], 1 )
}
