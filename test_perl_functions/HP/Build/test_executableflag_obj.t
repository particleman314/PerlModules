#!/usr/bin/env perl

use strict;
use warnings;

use File::Path;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
  require_ok('HP/TestTools.pl');
  use_ok("HP::Build::ExecutableFlag");
}

use Data::Dumper;

my $obj = HP::Build::ExecutableFlag->new();
is ( $obj->valid() == 0 , 1 );
diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);

$obj->set_name('--perl');
is ( defined($obj->name()), 1 );
is ( $obj->valid() == 1 , 1 );
diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);

$obj->clear();
is ( $obj->valid() == 0 , 1 );
diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);

$obj->set_value('666');
is ( defined($obj->value()), 1 );
is ( $obj->valid() == 0 , 1 );
diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);

$obj->set_name('--perl');
is ( defined($obj->name()), 1 );
is ( $obj->valid() == 1 , 1 );
diag($obj->as_json());
diag($obj->as_xml());
print STDERR "\n". Dumper($obj);
