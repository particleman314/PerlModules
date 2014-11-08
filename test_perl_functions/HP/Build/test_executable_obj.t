#!/usr/bin/env perl

use strict;
use warnings;

use File::Path;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
  require_ok('HP/TestTools.pl');
  use_ok("HP::Build::Executable");
  use_ok("HP::Path");
}

use Data::Dumper;

my $obj = HP::Build::Executable->new();
is ( $obj->valid() == 0 , 1 );
diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);

$obj->set_executable($^X);
is ( defined($obj->path()), 1 );
is ( defined($obj->executable()), 1);
is ( $obj->valid() == 1 , 1 );

my $fullpath = &join_path($obj->path(), $obj->executable());
is ( $fullpath eq $obj->get_executable(), 1);

diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);

$obj->clear();
is ( $obj->valid() == 0 , 1 );
diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);