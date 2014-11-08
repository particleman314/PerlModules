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
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::Providers::Provider__');
is ( defined($obj), 1 );

my $type = $obj->get_provider_type();
is ( (not defined($type)), 1 );

$obj->hptype('internal');
$type = $obj->get_provider_type();
is ( defined($type), 1 );
is ( $type eq 'internal', 1 );

&debug_obj($obj);