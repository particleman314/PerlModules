#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More tests => 2;

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::FileManager');
  }

my @directories = (
				   "$FindBin::Bin/../..",
				   );

foreach my $d (@directories) {
  my $result = &collect_all_files("$d");
  diag("\nDirectory <$d>\nhas ". scalar(@{$result}) . " files\n");
  &debug_obj($result);
}