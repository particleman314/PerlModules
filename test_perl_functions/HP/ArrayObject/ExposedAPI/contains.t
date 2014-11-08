#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Tools');
	use_ok('HP::Array::Constants');
  }
  
my @input1 = ( 1 .. 5, 7 .. 10 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );

my $contains = $arrobj1->contains(1);
is ( $contains eq TRUE, 1 );
$contains = $arrobj1->contains(44);
is ( $contains eq FALSE, 1 );
$contains = $arrobj1->contains(undef);
is ( $contains eq FALSE, 1 );

&debug_obj($arrobj1);