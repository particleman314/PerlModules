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

my $result = &HP::Support::Screen::__use_ioctl();
is ( defined($result), 1 );
&debug_obj($result);

if ( $result eq PASS ) {
  my ($rw, $cs) = ( $HP::Support::Screen::TermIORows, $HP::Support::Screen::TermIOCols );
  &debug_obj([ $rw, $cs ]);
}