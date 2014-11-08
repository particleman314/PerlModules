#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Hash');
	use_ok('HP::Support::Hash::Constants');
  }

my ($key, $value) = &convert_data_to_kv();
is ( (not defined($key)), 1 );
is ( (not defined($value)), 1 );

($key, $value) = &convert_data_to_kv('sample');
is ( defined($key), 1 );
is ( defined($value), 1 );
is ( $key eq &DUMMY_KEY, 1 );
is ( $value eq 'sample', 1 );

($key, $value) = &convert_data_to_kv('sample', 'result');
is ( defined($key), 1 );
is ( defined($value), 1 );
is ( $key eq &DUMMY_KEY, 1 );
is ( $value eq 'sample', 1 );

($key, $value) = &convert_data_to_kv(['sample->depth', 'This', 'is', 'a', 'group', 'of', 'words']);
is ( defined($key), 1 );
is ( defined($value), 1 );
is ( $key eq 'sample->depth', 1 );
is ( scalar(@{$value}) eq 6, 1 );
&debug_obj($key);
&debug_obj($value);

($key, $value) = &convert_data_to_kv({'key' => 'sample', 'value' => ['This', 'is', 'a', 'group', 'of', 'words']});
is ( defined($key), 1 );
is ( defined($value), 1 );
is ( $key eq 'sample', 1 );
is ( scalar(@{$value}) eq 6, 1 );
&debug_obj($key);
&debug_obj($value);