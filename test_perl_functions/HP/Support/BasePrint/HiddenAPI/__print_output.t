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

my $result = &HP::Support::BasePrint::__print_output();
is ( (not defined($result)), 1 );
&debug_obj($result);

&HP::Support::BasePrint::__print_output("XYZ");
$result = &HP::Support::BasePrint::__print_output("XYZ");
is ( (not defined($result)), 1 );
&debug_obj($result);

$result = &HP::Support::BasePrint::__print_output("XYZ", 'SIMPLE');
is ( (not defined($result)), 1 );
&debug_obj($result);

$result = &HP::Support::BasePrint::__print_output("XYZ", 'SIMPLE_WITH_RETURN', TRUE());
is ( defined($result), 1 );
&debug_obj($result);

$result = &HP::Support::BasePrint::__print_output({'data' => "XYZ", 'prefix' => 'TRIAL'});
is ( (not defined($result)), 1 );
&debug_obj($result);

$result = &HP::Support::BasePrint::__print_output({'data' => "XYZ", 'prefix' => 'TRIAL_WITH_RETURN', 'reply' => TRUE()});
is ( defined($result), 1 );
&debug_obj($result);
