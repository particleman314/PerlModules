#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Job::ParameterArray');
}

my $pa = HP::Job::ParameterArray->new();
is ( defined($pa), 1 );
is ( $pa->parameters()->number_elements() eq 0, 1 );

&debug_obj($pa);