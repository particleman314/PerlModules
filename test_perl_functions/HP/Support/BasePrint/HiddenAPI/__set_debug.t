#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::PerlModuleUtils');
    use_ok('HP::Support::BasePrint');
  }

my $before_call = $HP::Support::BasePrint::is_debug;
&HP::Support::BasePrint::__set_debug();
my $after_call = $HP::Support::BasePrint::is_debug;

is ( $before_call eq $after_call, 1 );

$before_call = $HP::Support::BasePrint::is_debug;
&HP::Support::BasePrint::__set_debug(TRUE());
$after_call = $HP::Support::BasePrint::is_debug;

is ( $before_call ne $after_call, 1 );