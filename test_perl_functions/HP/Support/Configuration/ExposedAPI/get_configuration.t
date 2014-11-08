#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
    use_ok('HP::Support::Configuration');
  }

&save_to_configuration({'data' => [ 'sample', 'result' ]});
&save_to_configuration({'data' => [ 'way->too->deep', 'wow' ]});

my $result = &get_configuration();
is ( defined($result), 1 );

&debug_obj(&get_configuration());