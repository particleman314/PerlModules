#!/usr/bin/env perl

use strict;
use warnings;

use File::Path;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
  require_ok('HP/TestTools.pl');
  use_ok("HP::Build::JobOutput");
}

use Data::Dumper;

my $obj = HP::Build::JobOutput->new();
diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);
