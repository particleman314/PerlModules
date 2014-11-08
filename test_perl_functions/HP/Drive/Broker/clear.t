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
	use_ok('HP::Support::Os');
	use_ok('HP::Path');
  }
  
my $tempdir = &MakeTempDir('BROKER');
my $dbfile  = &join_path("$tempdir", 'testDBfile.db');

my $obj = &create_object('c__HP::Drive::MapperDB::Broker__');
is ( defined($obj), 1 );

$obj->dbfile("$dbfile");
my $status = $obj->connect();
is ( $status eq PASS, 1 );

$obj->clear();

&debug_obj($obj);