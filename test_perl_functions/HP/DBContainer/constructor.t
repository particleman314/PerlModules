#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::DBContainer');
}

&createDBs();
my $result = &getDB();
is ( (not defined($result)), 1 );

$result = &getDB('HowdyDoody');
is ( (not defined($result)), 1 );

$result = &getDB('stream');
is ( defined($result), 1 );
&debug_obj($result);

$result = &getDB('lock');
is ( defined($result), 1 );
&debug_obj($result);

$result = &getDB('drive');
is ( defined($result), 1 );
&debug_obj($result);
&shutdownDBs();