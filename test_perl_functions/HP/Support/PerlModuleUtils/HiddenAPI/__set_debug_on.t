#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::PerlModuleUtils');
  }

my $before_result = $HP::Support::PerlModuleUtils::is_debug;
&HP::Support::PerlModuleUtils::__set_debug_on();
my $after_result = $HP::Support::PerlModuleUtils::is_debug;

is ( $before_result ne $after_result, 1 );

$before_result = $HP::Constants::is_debug;
&HP::Support::PerlModuleUtils::__set_debug_on('HP::Constants');
$after_result = $HP::Constants::is_debug;

is ( $before_result ne $after_result, 1 );