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

my $default_LS = $HP::Support::Screen::LINESPACE;
my ($rw, $cs) = ( $HP::Support::Screen::TermIORows, $HP::Support::Screen::TermIOCols );

my $LS = &get_linespace();
is ( defined($LS), 1 );
is ( $LS eq $default_LS, 1 );


