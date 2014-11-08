#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('File::Spec');
    use_ok('HP::FileManager');
  }
