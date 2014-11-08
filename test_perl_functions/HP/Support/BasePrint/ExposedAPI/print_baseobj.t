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

&HP::Support::BasePrint::print_baseobj();
&HP::Support::BasePrint::print_baseobj("XYZ");
&HP::Support::BasePrint::print_baseobj(\"ABC");
&HP::Support::BasePrint::print_baseobj([ 'A', 'B' ]);
&HP::Support::BasePrint::print_baseobj({'key1' => 'value1', 'key2' => 'value2'});