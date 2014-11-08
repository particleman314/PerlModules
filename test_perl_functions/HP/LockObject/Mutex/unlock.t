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
	use_ok('HP::Lock::Constants');
	use_ok('HP::Support::Os');
	use_ok('HP::Os');
	use_ok('HP::FileManager');
	use_ok('HP::DBContainer');
}

&createDBs();
my $lock = &create_object('c__HP::Lock::Mutex__');
is ( defined($lock), 1 );
is ( $lock->type() eq FILELOCK, 1 );

$lock->filepath("$FindBin::Bin/.spinlock");
$lock->key('U:'.&get_username());

&debug_obj($lock);
$lock->lock();

is ( -f $lock->filepath(), 1 );
is ( defined($lock->get_key()), 1 );

diag('Please wait...');
sleep 5;

my $result = $lock->unlock();
is ( $result eq TRUE, 1 );

&debug_obj($lock);
&shutdownDBs();
