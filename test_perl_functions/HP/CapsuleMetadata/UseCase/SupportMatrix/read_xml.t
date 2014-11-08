#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::SupportMatrix__');
is ( defined($obj), 1 );

my $uc_xmlfile = "$FindBin::Bin/test_usecase_manifest-support.xml";
$obj->readfile("$uc_xmlfile");

is ( $obj->providers()->number_elements() > 0, 1 );

&debug_obj($obj);