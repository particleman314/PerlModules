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
is ( defined($obj), TRUE );

my $permit_tags = $obj->__data_types();

is ( exists($permit_tags->{&PERMIT_TAG}) == 1, 1 );
&debug_obj($permit_tags);
