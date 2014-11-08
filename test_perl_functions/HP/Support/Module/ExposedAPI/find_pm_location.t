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

my $result = &find_pm_location();
is ( scalar(@{$result}) eq 0, 1 );

$result = &find_pm_location('Text::Format');
&debug_obj($result);

$result = &find_pm_location('Text/Format.pm');
&debug_obj($result);

$result = &find_pm_location('Text::Format', 'HP::Constants', 'HP::Support::Module');
&debug_obj($result);
