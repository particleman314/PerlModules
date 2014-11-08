#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::LockObject');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Lock::Constants');
	use_ok('HP::Support::Os');
	use_ok('HP::Os');
	use_ok('HP::DBContainer');
}

&createDBs();
my $lock = &create_object('c__HP::LockObject__');
is ( defined($lock), 1 );
is ( $lock->type() eq FILELOCK, 1 );


$lock->key('U:'.&get_username().'--M:'.&get_hostname.'--FP:'.$FindBin::Bin);
$lock->display();
is ( defined($lock->get_key()), 1 );

&debug_obj($lock);
&shutdownDBs();