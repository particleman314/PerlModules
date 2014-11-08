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

my ($rw, $cs) = ( $HP::Support::Screen::TermIORows, $HP::Support::Screen::TermIOCols );

&get_screen_info();

my ($rw_2, $cs_2) = ( $HP::Support::Screen::TermIORows, $HP::Support::Screen::TermIOCols );

is ( $rw_2 ne $rw, 1 );
is ( $cs_2 ne $cs, 1 );

