#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Base::Constants');
    use_ok('HP::Support::Object::Tools');
  }

my $obj = &create_object('c__HP::BaseObject__');

$obj->instantiate();
my @keys = keys( %{$obj} );
is ( scalar(@keys) == 0, 1 );

my $xmlobj = &create_object('c__HP::XMLObject__');

$obj->instantiate($xmlobj);
@keys = keys( %{$obj} );
is ( scalar(@keys) == 0, 1 );

&debug_obj($obj);