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

&save_to_configuration({'data' => [ 'sample', 'result']});
my $result = &get_from_configuration('sample');
is ( defined($result), 1 );
is ( ${$result} eq 'result', 1 );

&save_to_configuration({'data' => [ 'way->too->deep', 'wow']});
$result = &get_from_configuration('way->too->deep');
is ( defined($result), 1 );
is ( ${$result} eq 'wow', 1 );

&clear_configuration('sample');
$result = &get_from_configuration('sample');
is ( ( not defined($result) ), 1 );
$result = &get_from_configuration('way->too->deep');
is ( defined($result), 1 );
is ( ${$result} eq 'wow', 1 );

&clear_configuration('way->too');
$result = &get_from_configuration('way->too->deep');
is ( ( not defined($result) ), 1 );
$result = &get_from_configuration('way');
is ( defined($result), 1 );
