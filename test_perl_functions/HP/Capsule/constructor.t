#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Capsule::CapsuleDirective');
  }
  
my $arrobj1 = HP::Capsule::CapsuleDirective->new();
is ( defined($arrobj1), 1 );
&debug_obj($arrobj1);