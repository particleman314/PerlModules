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

&save_to_configuration(['sample', 'result']);
&save_to_configuration(['way->too->deep', 'wow']);

my @data = qw( This is an array of words );

&save_to_configuration(['way->too->deep2', \@data]);

my %data = ( kenpo_belts => [ 'white', 'yellow', 'orange', 'purple', 'blue', 'green', 'red', 'brown', 'black' ] );

&save_to_configuration(['another_hash', \%data]);

&show_configuration(undef, TRUE);
&debug_obj(&get_configuration());