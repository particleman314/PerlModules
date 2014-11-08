#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
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

my $setres1 = $setobj1->intersect($setobj2);
my @contents = $setres1->get_elements();
is ( scalar(@contents) == 5, 1 );

my $setres2 = $setobj1->intersect($setobj3);
@contents = $setres2->get_elements();
is ( scalar(@contents) == 5, 1 );

&debug_print_xml($setres1);
&debug_print_json($setres2);
&debug_print_dumper($setobj1);