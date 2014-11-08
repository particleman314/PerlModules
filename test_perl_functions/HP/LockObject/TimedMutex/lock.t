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
	use_ok('HP::Os');
	use_ok('HP::DBContainer');
}

&createDBs();
my $lock = &create_object('c__HP::Lock::TimedMutex__');
is ( defined($lock), 1 );
is ( $lock->type() eq FILELOCK, 1 );

$lock->filepath("$FindBin::Bin/.spinlock");
$lock->key('U:'.&get_username());
$lock->update_timeout(-10);

is ( $lock->timeout() eq DEFAULT_TIMEOUT, 1 );

$lock->update_timeout(5.5);
is ( $lock->timeout() eq DEFAULT_TIMEOUT, 1 );

$lock->update_timeout(2);
is ( $lock->timeout() eq 2, 1 );

$lock->start();
&debug_obj($lock);

is ( -f $lock->filepath(), 1 );
is ( defined($lock->get_key()), 1 );

sleep 5;

&debug_obj($lock);
&shutdownDBs();
