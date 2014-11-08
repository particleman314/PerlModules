#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
    use_ok('HP::Support::Base');
  }

my $input = ' ';
my $result = &valid_string($input);
is ( $result eq FALSE, 1 );

&HP::Support::Base::allow_space_as_valid_string(TRUE);
$result = &valid_string($input);
is ( $result eq TRUE, 1 );

&HP::Support::Base::allow_space_as_valid_string(FALSE);
$result = &valid_string($input);
is ( $result eq FALSE, 1 );
