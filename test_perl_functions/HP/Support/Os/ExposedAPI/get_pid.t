#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok("HP::Constants");
	use_ok("HP::CheckLib");
    use_ok("HP::Support::Os");
  }

my $pid = &get_pid();
my $satisfy = &is_numeric($pid);
is ( $satisfy eq TRUE, 1);
is ( $pid > 0, 1 );
is ( $pid < 2**17, 1 );

$pid = &get_pid(12345);
is ( $pid == 12345, 1 );
