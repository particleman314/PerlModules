#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::Support::Object::Tools');
  }

my $obj = &create_instance('c__HP::StreamDB__');
is ( defined($obj) == 1, 1 );
is ( $obj->number_streams() == 3, 1 );
&debug_obj($obj);
