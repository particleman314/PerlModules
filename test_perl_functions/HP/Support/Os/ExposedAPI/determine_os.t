#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Os');
	use_ok('HP::Support::Os::Constants');
  }

my $ostype = &determine_os();
is ( $ostype ne UNKNOWN_OS_TYPE, 1);
