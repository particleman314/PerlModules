#!/usr/bin/env perl

use strict;
use warnings;

use File::Path;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
  require_ok('HP/TestTools.pl');
  use_ok("HP::Build::Job");
}

use Data::Dumper;

my $obj = HP::Build::Job->new();
#is ( $obj->completed() == 0 , 1 );
#diag($obj->as_json());
#diag($obj->as_xml());
#print STDERR "\n". Dumper($obj);

$obj->set_executable($^X);
#diag($obj->as_json());
#diag($obj->as_xml());
#print STDERR "\n". Dumper($obj);

$obj->set_executable($^X);
#diag($obj->as_json());
#diag($obj->as_xml());
#print STDERR "\n". Dumper($obj);

$obj->add_exe_flag('--perl');
$obj->add_exe_flag('--stop');

diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);
