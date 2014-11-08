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

my $result = &HP::Support::BasePrint::__print_inputs();
is ( (not defined($result)), 1 );
&debug_obj($result);

$result = &HP::Support::BasePrint::__print_inputs("XYZ");
is ( defined($result), 1 );
&debug_obj($result);

$result = &HP::Support::BasePrint::__print_inputs("XYZ", "Start Time", 3);
is ( defined($result), 1 );
&debug_obj($result);
