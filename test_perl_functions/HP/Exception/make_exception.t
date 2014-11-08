#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Exception::Tools');
	use_ok('HP::DBContainer');
  }
  
&createDBs();
my $obj = &create_object('c__HP::Exception__');
is ( defined($obj), 1 );

$obj->display();
&debug_obj($obj);

my $obj1 = &create_object('c__HP::Exception__');
$obj1->message('This is a test');

&debug_obj($obj1);

my $obj2 = &create_object('c__HP::Exception__');
$obj2->message('This should print out to the screen');
$obj2->handles([ 'STDERR' ]);
$obj2->display();

is ( defined($obj2->handles()->[0]), 1 );

my $obj3 = &make_exception();
is ( (not defined($obj3)), 1 );
&debug_obj($obj3);

my $obj4 = &make_exception('HP::Exception');
&debug_obj($obj4);

my $obj5 = &make_exception('HP::FileManager::Exception::ChangePermissions');
&debug_obj($obj5);
&shutdownDBs();

