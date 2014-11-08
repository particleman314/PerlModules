#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Lock::Constants');
	use_ok('HP::Support::Os');
	use_ok('HP::DBContainer');
}

&createDBs();
my $lock = &create_object('c__HP::Lock::Semaphore__');
is ( defined($lock), 1 );
is ( $lock->type() eq FILELOCK, 1 );

$lock->display();

$lock->type(MMAP);
$lock->data({'pid' => &get_pid()});

is ( $lock->type() eq MMAP, 1 );
$lock->display();

$lock->increment();
$lock->increment();

$lock->display();
&debug_obj($lock);
&shutdownDBs();