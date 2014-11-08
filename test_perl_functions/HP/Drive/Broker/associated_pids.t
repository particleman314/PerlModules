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

my $fp = "$FindBin::Bin";
my $drvltr = "Z:";

my $drvmap = &create_object('c__HP::Drive::MapperDB::DriveMapping__');
$drvmap->fullpath("$fp");
$drvmap->reduced_path("$drvltr");

my $mypid = &get_pid();

my $encoded_data = $obj->encode($drvmap);
is ( defined($encoded_data), 1 );

&debug_obj($encoded_data);

my $matched_records = $obj->scan_db_for_pid($mypid);
is ( scalar(@{$matched_records}), 0 );
&debug_obj($matched_records);

$obj->increment($drvmap->fullpath(), $drvmap->reduced_path(), $mypid);

$matched_records = $obj->scan_db_for_pid($mypid);
is ( scalar(@{$matched_records}), 1 );
&debug_obj($matched_records);

my $number_records = $obj->number_records();
is ( $number_records, 1 );
&debug_obj($number_records);

my $drvmap_key = $obj->make_key("$fp", "$drvltr");

my $associated_pids = $obj->associated_pids("$drvmap_key");
&debug_obj($associated_pids);
&debug_obj($mypid);

my $number_pids_in_record = $obj->number_pids("$drvmap_key");
is ( $number_pids_in_record, 1 );

&debug_obj($obj);