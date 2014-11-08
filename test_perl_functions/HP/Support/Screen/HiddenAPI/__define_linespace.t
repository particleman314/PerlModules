#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
    use_ok('HP::Support::Screen');
  }

my $LSchar = "*";
my ($rw, $cs) = ( $HP::Support::Screen::TermIORows, $HP::Support::Screen::TermIOCols );
my $new_LS = "$LSchar" x int($cs/length($LSchar));

my $LS = &get_linespace();
is ( defined($LS), 1 );
is ( $LS eq $new_LS, 1 );

$LSchar = "#";
&HP::Support::Screen::__define_linespace('#');
$new_LS = "$LSchar" x int($cs/length($LSchar));

$LS = &get_linespace();
is ( defined($LS), 1 );
is ( $LS eq $new_LS, 1 );

$LSchar = "#=";
&HP::Support::Screen::__define_linespace('#=');
$new_LS = "$LSchar" x int($cs/length($LSchar));

$LS = &get_linespace();
is ( defined($LS), 1 );
is ( $LS eq $new_LS, 1 );
