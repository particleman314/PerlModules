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
	use_ok('HP::Support::Base::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Utilities');
  }

my $obj = &create_object('c__HP::BaseObject__');
$obj->add_data( 'XML', &create_object('c__HP::XMLObject__') );

&debug_obj($obj);

$obj->clear();

&debug_obj($obj);