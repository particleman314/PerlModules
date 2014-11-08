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

my $min = 0;
my $max = 10;
my @choices = &MakeNumbers($min + 1, $max - 1, 10, 1);
foreach ( @choices ) {
  my $result = &limit($min, $max, $_);
  is ( $result > $min, 1 );
  is ( $result < $max, 1 );
}

$result = &limit( $min, $max, $min );
is ( $result == $min, 1 );

$result = &limit( $min, $max, $max );
is ( $result == $max, 1 );

$result = &limit( $min, $max, $max + 1);
is ( $result == $max, 1 );

$result = &limit( $min, $max, $min - 1);
is ( $result == $min, 1 );

$result = &limit( $min, $max, 'A' );
is ( $result eq FALSE, 1 );

$result = &limit( $min, 'A', $max );
is ( $result eq FALSE, 1 );