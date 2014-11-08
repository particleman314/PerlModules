#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::PerlModuleUtils');
  }

my $module = 'HP/Constants.pm';
my $inINChash = exists($INC{$module});
is ( $inINChash eq 1, 1 );

&load_required_modules({'perl_modules' => ['HP::Constants']});
$inINChash = exists($INC{$module});
is ( $inINChash eq 1, 1 );

is ( TRUE() eq 1, 1 );
&debug_obj(TRUE());