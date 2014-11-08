#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Module');
  }

my $module = undef;
my $result = &get_full_qualified_module_name($module);
is ( (not defined($result)) == 1, 1 );
