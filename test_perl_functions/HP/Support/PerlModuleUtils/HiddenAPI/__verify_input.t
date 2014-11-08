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

my $result = &HP::Support::PerlModuleUtils::__verify_input();
is ( (not defined($result)), 1 );

&debug_obj($result);

$result = &HP::Support::PerlModuleUtils::__verify_input('Scalar Term');
is ( (not defined($result)), 1 );

&debug_obj($result);

$result = &HP::Support::PerlModuleUtils::__verify_input(['Text::Format', 'Data::Dumper']);
is ( defined($result), 1 );

&debug_obj($result);

$result = &HP::Support::PerlModuleUtils::__verify_input({'Text::Format' => 'undef', 'Data::Dumper' => '3.14'});
is ( defined($result), 1 );

&debug_obj($result);
