#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }

my $srchobj1 = &create_object('c__HP::Array::SearchAlgorithms::GenericSearch__');

my $clone_enabled = $srchobj1->cloning_enabled();
is ( $clone_enabled eq TRUE, 1 );

$srchobj1->__turn_off_cloning();

$clone_enabled = $srchobj1->cloning_enabled();
is ( $clone_enabled eq FALSE, 1 );

$srchobj1->__turn_on_cloning();

$clone_enabled = $srchobj1->cloning_enabled();
is ( $clone_enabled eq TRUE, 1 );
