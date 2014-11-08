#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Base');
    use_ok('HP::Support::Hash');
  }

my @inputs = qw( Hello World );
push (@inputs, undef);

&debug_obj(\@inputs);

my $inputhash = &convert_input_to_hash([ 'first', \&valid_string,
                                         'second', \&valid_string ], @inputs);
is ( scalar(keys(%{$inputhash})) == 3, 1 );
is ( exists($inputhash->{'non-named_params'}) == 1, 1 );

&debug_obj($inputhash);

$inputhash = &convert_input_to_hash([ 'first',  \&valid_string,
                                      'second', \&valid_string,
									  'third',  \&valid_string ], @inputs);
is ( scalar(keys(%{$inputhash})) == 2, 1 );
is ( exists($inputhash->{'non-named_params'}) == 0, 1 );
&debug_obj($inputhash);

$inputs[2] = 'It';
push (@inputs, 'is');
push (@inputs, 'a');
push (@inputs, 'mad');
push (@inputs, 'mad');
push (@inputs, 'world...');

$inputhash = &convert_input_to_hash([ 'first', \&valid_string,
                                      'second', \&valid_string,
									  'third', \&valid_string ], @inputs);
is ( scalar(keys(%{$inputhash})) == 4, 1 );
is ( exists($inputhash->{'non-named_params'}) == 1, 1 );
&debug_obj($inputhash);
