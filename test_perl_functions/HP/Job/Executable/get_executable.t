#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Os');
	use_ok('HP::Path');
	use_ok('HP::DBContainer');
}

&createDBs();
my $exe = &create_object('c__HP::Job::Executable__');
is ( defined($exe), 1 );

my $result = $exe->get_executable();
is ( (not defined($result)), 1 );

$exe->set_executable('C:\ManagedSoftware\7-Zip_9.20\7z.exe');
$result = $exe->get_executable();

is ( defined($result), 1 );
is ( $result eq 'C:\ManagedSoftware\7-Zip_9.20\7z.exe', 1 );

&debug_obj($exe);

$exe->set_executable('java.exe');
$result = $exe->get_executable();

is ( defined($result), 1 );
my $answer = &convert_path_to_client_machine(&join_path("$FindBin::Bin/../../..",'java.exe'), &get_os_type());

is ( $result eq $answer, 1 );

&debug_obj($exe);
&shutdownDBs();