#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::CSL::DAO::LocalData__');
is ( defined($obj), 1 );
my $result = $obj->collect_all_dependencies();

is ( scalar(@{$result}) == 0, 1 );

my $lsf = "$FindBin::Bin/../../../SettingsFiles/local_settings_testfile.xml";

$obj->readfile("$lsf");
$result = $obj->collect_all_dependencies();
is ( scalar(@{$result}) == 3, 1 );

$result = $obj->collect_all_dependencies('OO10');
is ( scalar(@{$result}) == 2, 1 );

$result = $obj->collect_all_dependencies('OO20');
is ( scalar(@{$result}) == 0, 1 );

&debug_obj($obj);