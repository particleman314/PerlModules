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

&HP::Support::BasePrint::__print_debug_output();
&HP::Support::BasePrint::__print_debug_output("XYZ");

our $is_debug = 1;
$result = &HP::Support::BasePrint::__print_debug_output("XYZ");
is ( defined($result), 1 );
&debug_obj($result);
