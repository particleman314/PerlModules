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
				   "$FindBin::Bin/../../test_perl_functions/HP/Drive/Mapper",
				   "$FindBin::Bin/../../test_perl_functions/XYZ/123/fgfffjvdnssv/dauisdguaifdlfs/fhfjdfkd v/dfhsgdshgifsgh/fdsjakglsilguigfonsbgfjfdhfulfdjzvdsjfffghddfggf",
				   "$FindBin::Bin",
				   );

foreach my $d (@directories) {
  my $result = &collect_directory_contents("$d");
  diag("\nDirectory <$d>");
  &debug_obj($result);
}