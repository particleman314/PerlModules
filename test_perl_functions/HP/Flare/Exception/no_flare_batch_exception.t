#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Flare::Exception::NoFlareBatchException');
  }

use Data::Dumper;

print STDERR "\n";
my $obj = HP::Flare::Exception::NoFlareBatchException->new();
print STDERR Dumper($obj) ."\n";
