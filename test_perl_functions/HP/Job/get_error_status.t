#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Os');
	use_ok('HP::Path');
	use_ok('HP::DBContainer');
}

&createDBs();
my $job = &create_object('c__HP::Job__');
is ( defined($job), 1 );

my $flag = &create_object('c__HP::Job::ExecutableFlag__');
$flag->set_name('u');
$job->add_flags($flag);

my $refflag = '*.doc';
$job->add_flags(\$refflag);

my $exename = &convert_path_to_client_machine('C:/7zip/7z.exe', &get_os_type());

my $exe = &create_object('c__HP::Job::Executable__');
$exe->set_executable("$exename");
$job->set_executable($exe);

my $result = $job->get_error_status();
is ( defined($result), 1 );
is ( $result eq FAIL, 1 );
&debug_obj($job);
&shutdownDBs();