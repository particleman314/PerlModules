#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::DBContainer');
}

&createDBs();
my $lockDB = &create_instance('c__HP::LockDB__');
is ( defined($lockDB), 1 );

my $lock1 = &create_object('c__HP::Lock::Mutex__');
$lockDB->add_lock($lock1);

my $lock2 = &create_object('c__HP::Lock::TimedMutex__');
$lock2->update_timeout(50);
$lock2->filepath("$FindBin::Bin/trial.lock");

$lockDB->add_lock($lock2);

$lockDB->show_locks();

&debug_obj($lockDB);
&shutdownDBs();