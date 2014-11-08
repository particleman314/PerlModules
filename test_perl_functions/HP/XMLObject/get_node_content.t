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
my $node = $obj->get_nodes_by_xpath({'xpath' => '//subnode/build_date'});
is ( scalar(@{$node}) == 1, 1 );

my $content = $obj->get_node_content($node->[0]);
is ( defined($content), 1 );
is ( $content eq '2014-05-08 16:49:10', 1 );

&debug_obj( $obj );
