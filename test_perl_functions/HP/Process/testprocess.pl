#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use HP::Constants;
use HP::Os;
use HP::Path;
use HP::Support::Object::Tools;
use HP::FileManager;

my $testfile = &join_path("$FindBin::Bin",'testfile.txt');
if ( &does_file_exist("$testfile") eq TRUE ) {
  my $strobj   = &create_object('c__HP::Stream::IO::Output__');
  $strobj->validate();
  my $contents = $strobj->slurp("$testfile");

  print STDERR "AAAA -- $contents\n";

  foreach my $line (@{$contents}) {
    print "$line\n";
  }
}

exit 0;
