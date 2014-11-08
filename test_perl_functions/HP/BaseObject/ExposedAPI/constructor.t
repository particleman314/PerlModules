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
    use_ok('HP::BaseObject');
  }

my $obj = HP::BaseObject->new();
is ( defined($obj), TRUE );

&debug_obj($obj);

my $obj2 = HP::BaseObject->new();
is ( ref($obj) eq ref($obj2), TRUE );
is ( $obj->equals($obj2), TRUE );

&debug_obj($obj2);
