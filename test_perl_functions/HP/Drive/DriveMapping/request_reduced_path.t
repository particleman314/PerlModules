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
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::Drive::MapperDB::DriveMapping__');
is ( defined($obj), 1 );
$obj->fullpath("$FindBin::Bin");
$obj->reduced_path('Z:');

my $newpath = $obj->request_reduced_path(undef);
is ( (not defined($newpath)), 1 );

$newpath = $obj->request_reduced_path('');
is ( (not defined($newpath)), 1 );

$newpath = $obj->request_reduced_path('C:');
is ( $newpath eq $obj->fullpath(), 1 );

&debug_obj($obj);