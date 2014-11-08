#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Array::Exceptions::NoSuchElementException');
  }
  
my $arrex = HP::Array::Exceptions::NoSuchElementException->new();
is ( defined($arrex), 1 );
&debug_obj($arrex);
