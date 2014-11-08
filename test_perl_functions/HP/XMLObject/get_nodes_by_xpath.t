#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::XMLObject__');
is (defined($obj) == 1, 1);

my $xmlfile = "$FindBin::Bin/../SettingsFiles/test_output.xml";
$obj->xmlfile("$xmlfile");
$obj->readfile();

is ( defined($obj->xmlfile()), 1 );
my $xpath = '//subnode';

my $nodes = $obj->get_nodes_by_xpath({'xpath' => "$xpath"});
is ( scalar(@{$nodes}) > 0, 1 );

$xpath = '//abc/xyz';
$nodes = $obj->get_nodes_by_xpath({'xpath' => "$xpath"});
is ( scalar(@{$nodes}) == 0, 1 );

$xpath = '//subnode/build_date';
$nodes = $obj->get_nodes_by_xpath({'xpath' => "$xpath"});
is ( scalar(@{$nodes}) == 1, 1 );

&debug_obj( $obj );
