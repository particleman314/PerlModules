#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Exception');
  }

use Data::Dumper;

print STDERR "\n";
my $obj = HP::Exception->new();
diag($obj->as_xml());
diag($obj->as_json());
print STDERR Dumper($obj) ."\n";
