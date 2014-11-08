#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
{
    use_ok('HP::Process');
}

is ($HP::Process::keep_temp_files, 0);

&keep_temporaries();
is ($HP::Process::keep_temp_files, 0);

&keep_temporaries('abc');
is ($HP::Process::keep_temp_files, 0);

&keep_temporaries(-8);
is ($HP::Process::keep_temp_files, 0);

&keep_temporaries(6);
is ($HP::Process::keep_temp_files, 1);

&keep_temporaries('abc');
is ($HP::Process::keep_temp_files, 1);
