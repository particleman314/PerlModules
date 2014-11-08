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

my $encoded_data = undef;
my $result = $obj->decode($encoded_data);
is ( (not defined($result)), 1 );

$encoded_data = '';
$result = $obj->decode($encoded_data);
is ( (not defined($result)), 1 );

my $drvmap = &create_object('c__HP::Drive::MapperDB::DriveMapping__');
is ( defined($drvmap), 1 );

$drvmap->fullpath("$FindBin::Bin");
$drvmap->reduced_path("Z:");
$drvmap->pidlist()->push_item(&get_pid());

# Test queueset functionality [ NO SORT ]
$drvmap->pidlist()->push_item('5678');
$drvmap->pidlist()->push_item('1');
$drvmap->pidlist()->push_item('1');

$encoded_data = $obj->encode($drvmap);
is ( defined($encoded_data), 1 );

&debug_obj($encoded_data);

my $drvmap2 = $obj->decode($encoded_data);
is ( defined($drvmap2), 1 );
is ( &equal($drvmap, $drvmap2) eq TRUE, 1 );

&debug_obj($drvmap);
&debug_obj($drvmap2);
&debug_obj($obj);
