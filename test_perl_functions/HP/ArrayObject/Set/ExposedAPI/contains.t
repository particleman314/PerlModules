#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Tools');
	use_ok('HP::Array::Constants');
  }
  
my @input1 = ( 1 .. 5, 7 .. 10, -5 .. -1 );

my $setobj = &create_object('c__HP::Array::Set__');
$setobj->add_elements( {'entries' => \@input1, 'location' => APPEND} );

my $contains = $setobj->contains(1);
is ( $contains eq TRUE, 1 );
$contains = $setobj->contains(44);
is ( $contains eq FALSE, 1 );
$contains = $setobj->contains(undef);
is ( $contains eq FALSE, 1 );

&debug_obj($setobj);