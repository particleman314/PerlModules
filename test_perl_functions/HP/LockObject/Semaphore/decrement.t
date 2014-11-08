#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
}

my $lock = &create_object('c__HP::Lock::Semaphore__');
is ( defined($lock), 1 );

is ( $lock->refcount() eq 0, 1 );

$lock->decrement();
is ( $lock->refcount() eq 0, 1 );

$lock->increment();
is ( $lock->refcount() eq 1, 1 );

$lock->increment();
$lock->increment();

is ( $lock->refcount() eq 3, 1 );

$lock->decrement();
is ( $lock->refcount() eq 2, 1 );

&debug_obj($lock);
