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
	use_ok('HP::CheckLib');
  }

my $obj = &create_object('c__HP::BaseObject__');
is ( defined($obj), TRUE );

is ( ( not defined($obj->update_fields()) ), 1 );
$obj->update_fields('XML');
is ( defined($obj->{'ADDED_FIELDS'}), 1 );
is ( &is_type($obj->{'ADDED_FIELDS'}, 'HP::Array::Set') eq TRUE, 1 );
is ( $obj->{'ADDED_FIELDS'}->is_empty() eq FALSE, 1 );
is ( $obj->{'ADDED_FIELDS'}->number_elements() eq 1, 1 );

&debug_obj($obj);