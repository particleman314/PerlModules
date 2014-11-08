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

&HP::Support::PerlModuleUtils::__begin();
$HP::Support::PerlModuleUtils::is_debug = TRUE;
&HP::Support::PerlModuleUtils::__begin();
