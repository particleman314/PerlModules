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
	use_ok('HP::Support::Object');
    use_ok('HP::Support::Object::Tools');
  }

my $obj = &create_object('c__HP::BaseObject__');
is ( defined($obj), TRUE );

my $otherobj = &create_object('c__HP::XMLObject__');
$obj->add_data('XML', $otherobj);

my $fields = &get_fields($obj, FALSE);
is ( scalar(@{$fields}) == 1, 1 );

$obj->add_data('HASH', {'one' => 1});
$fields = &get_fields($obj, FALSE);
is ( scalar(@{$fields}) == 2, 1 );

&debug_obj($obj);
