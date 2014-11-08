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

my $otherobj = &create_object('c__HP::XMLObject__');
$obj->add_data('XML', $otherobj);

my $result = $obj->push_to_configuration();
is ( (not defined($result)), 1 );

$obj->{'get_storables'} = ['XML'];
$obj->{'root_property'} = 'ROOT_LEVEL';

$result = $obj->push_to_configuration();
is ( defined($result), 1 );

&debug_obj($result);
&debug_obj($obj);