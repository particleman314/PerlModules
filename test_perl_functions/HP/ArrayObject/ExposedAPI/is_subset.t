#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('List::Util');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Tools');
	use_ok('HP::Array::Constants');
  }
  
my @input1 = ( 1 .. 10 );
my @input2 = ( 1 .. 5 );
my @input3 = ( 6 .. 10 );

my $setobj1 = &create_object('c__HP::Array::Set__');
my $setobj2 = &create_object('c__HP::Array::Set__');
my $setobj3 = &create_object('c__HP::Array::Set__');

$setobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );
$setobj2->add_elements( {'entries' => \@input2, 'location' => APPEND} );
$setobj3->add_elements( {'entries' => \@input3, 'location' => APPEND} );

my $result = &is_subset($setobj2, $setobj1);
is ( $result eq TRUE, 1 );

$result = &is_subset($setobj3, $setobj1);
is ( $result eq TRUE, 1 );

$result = &is_subset($setobj1, $setobj1);
is ( $result eq TRUE, 1 );

$result = &is_subset($setobj1, $setobj3);
is ( $result eq FALSE, 1 );

$result = &is_subset($setobj2, $setobj3);
is ( $result eq FALSE, 1 );

$result = &is_subset($setobj3, $setobj2);
is ( $result eq FALSE, 1 );
