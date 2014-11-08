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
my $nodenames = $obj->get_nodenames();
is ( scalar(@{$nodenames}) > 0, 1 );

my $subnode = $obj->get_nodes_by_xpath({'xpath' => '//subnode'});
$nodenames = $obj->get_nodenames($subnode->[0]);
is ( scalar(@{$nodenames}) == 3, 1 );

&debug_obj( $obj );
