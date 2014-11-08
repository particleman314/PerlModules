#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('Cwd');
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
	use_ok('HP::Support::Object::Tools');
    use_ok('HP::FileManager');
    use_ok('HP::Path');
  }

my $snooze   = $ARGV[0] || 2;
my $tempdir  = &MakeTempDir('FS_ATTR');
my $filename = &join_path("$tempdir",'trial1');

my $strobj = &create_object('c__HP::Stream::IO::Output__');

$strobj->touch_file("$filename");

my $fs  = &get_attribute("$filename",'file_size');
my $hlc = &get_attribute("$filename",'hard_link_cnt');
my $ba  = &get_attribute("$filename",'blk_allocated');

is ($fs,0);
is ($hlc,1);

if ( not &os_is_windows() ) {
   rmtree("$filename");

   $strobj->touch_file("$filename");
   my $creation_time = &get_attribute("$filename",'creation_time');

   sleep $snooze;

   my @contents = $strobj->slurp("$filename");

   is ((&get_attribute("$filename",'access_time') - $snooze), $creation_time);
}
rmtree("$tempdir");

sub get_file_times($)
  {
     my @results = ();
     push(@results, &get_attribute("$_[0]",'access_time'));
     push(@results, &get_attribute("$_[0]",'creation_time'));
     push(@results, &get_attribute("$_[0]",'modify_time'));
     return @results;
  }
