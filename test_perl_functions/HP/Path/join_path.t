#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    use_ok('HP::Os');
    use_ok('HP::Path');
}

my $dirsep = &get_dir_sep();

is(&join_path('a', 'b'), "a${dirsep}b");
is(&join_path('a', 'b', 'c'), "a${dirsep}b${dirsep}c");
is(&join_path('c:/', 'foosball'), "c:${dirsep}foosball");
is(&join_path('/home/foosball', '/tmp/foosball'), "${dirsep}tmp${dirsep}foosball");
