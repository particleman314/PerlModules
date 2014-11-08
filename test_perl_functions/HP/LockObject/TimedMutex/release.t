#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
}

my $lock = &create_object('c__HP::Lock::Mutex__');
is ( defined($lock), 1 );

$lock->key('12345');
$lock->active(TRUE);
$lock->filepath("$FindBin::Bin/.spinlock");

&debug_obj($lock);

$lock->release();
is ( (not -f "$lock->filepath()"), 1 );

&debug_obj($lock);
