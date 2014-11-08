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

my $str = undef;
my $decode = &is_class_rep($str);
is ( defined($decode), 1 );
is ( (not defined($decode->{'class'})), 1 );
is ( (not defined($decode->{'style'})), 1 );

$str = 'c__HP::ArrayObject__';
$decode = &is_class_rep($str);
is ( defined($decode), 1 );
is ( defined($decode->{'class'}), 1 );
is ( $decode->{'class'} eq 'HP::ArrayObject', 1 );
is ( defined($decode->{'style'}), 1 );
is ( $decode->{'style'}->[0] eq FALSE, 1 );

$str = '[HP::Array::Set] c__HP::XYZ__';
$decode = &is_class_rep($str);
is ( defined($decode), 1 );
is ( defined($decode->{'class'}), 1 );
is ( $decode->{'class'} eq 'HP::XYZ', 1 );
is ( defined($decode->{'style'}), 1 );
is ( $decode->{'style'}->[0] eq TRUE, 1 );
is ( $decode->{'style'}->[1] eq 'HP::Array::Set', 1 );
