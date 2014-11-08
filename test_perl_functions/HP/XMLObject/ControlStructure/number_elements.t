#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::XML::ControlStructure');
	use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::XML::ControlStructure__');
is (defined($obj) == 1, 1);

$obj->get_attribute_fields()->add_elements({'entries' => ['one', 'two']});

my $result = $obj->number_elements(); # No field given to interrogate
is ( $result == -1, 1 );

$result = $obj->number_elements('skipped_fields');
is ( $result == 0, 1 );

$result = $obj->number_elements('attribute_fields');
is ( $result == 2, 1 );

&debug_obj( $obj );