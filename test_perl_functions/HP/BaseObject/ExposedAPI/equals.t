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
$obj->add_data( 'XML', &create_object('c__HP::XMLObject__') );

my $obj2 = &clone_item($obj);
is ( $obj->equals($obj2) eq TRUE, 1 );

$obj2->{'XML'}->rootnode(1);

is ( $obj->equals($obj2) eq FALSE, 1 );
&debug_obj($obj);
&debug_obj($obj2);