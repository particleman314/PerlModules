#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok("HP::Constants");
    use_ok("HP::Support::Configuration");
  }

&save_to_configuration({'data' => [ 'sample', 'result' ]});
my $result = &get_from_configuration('sample');
is ( defined($result), 1 );
is ( ${$result} eq 'result', 1 );

&save_to_configuration({'data' => [ 'way->too->deep', 'wow' ]});
$result = &get_from_configuration('way->too->deep');
is ( defined($result), 1 );
is ( ${$result} eq 'wow', 1 );

my @data = qw( This is an array of words );

&save_to_configuration({'data' => [ 'way->too->deep2', \@data ]});
$result = &get_from_configuration('way->too->deep2');
is ( defined($result), 1 );
is ( ref($result) =~ m/^array/i, 1 );

$result = &get_from_configuration('way->too');
is ( defined($result), 1 );
is ( ref($result) =~ m/^hash/i, 1 );

my %data = ( kenpo_belts => [ 'white', 'yellow', 'orange', 'purple', 'blue', 'green', 'red', 'brown', 'black' ] );

&save_to_configuration({'data' => [ 'another_hash', \%data ]});
$result = &get_from_configuration('another_hash');
is ( defined($result), 1 );
is ( ref($result) =~ m/^hash/i, 1 );

&debug_obj(&get_configuration());