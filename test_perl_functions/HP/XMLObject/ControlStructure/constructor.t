#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::XML::ControlStructure');
  }
  
my $obj = HP::XML::ControlStructure->new();
is (defined($obj) == 1, 1);

&debug_obj( $obj );