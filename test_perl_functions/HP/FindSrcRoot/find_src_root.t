#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use lib "$FindBin::Bin/../../../PerlModules";

use Test::More tests => 2;

BEGIN
  {
    use_ok("HP::FindSrcRoot");
  }

isnt(&find_src_root(), undef);
