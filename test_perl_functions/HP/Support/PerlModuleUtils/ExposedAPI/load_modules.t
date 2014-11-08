#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::PerlModuleUtils');
  }

my $module = 'HP::Constants';
my $result = &load_modules({'perl_modules' => [ $module ]});

is ( $result eq TRUE(), 1 );
