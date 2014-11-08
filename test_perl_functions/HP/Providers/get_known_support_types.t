#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Tools');
  }
  
my $obj = &create_object('c__HP::ProviderList__');
is ( defined($obj), 1 );

my $types = $obj->get_known_support_types();
is ( defined($types), 1 );
is ( scalar(@{$types}) == 2, 1 );
is ( &set_contains('internal', $types) eq TRUE, 1 );
is ( &set_contains('external', $types) eq TRUE, 1 );

&debug_obj($obj);