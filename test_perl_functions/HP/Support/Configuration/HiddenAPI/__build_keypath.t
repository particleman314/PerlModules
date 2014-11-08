#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Configuration');
	use_ok('HP::CheckLib');
  }

my $result = &HP::Support::Configuration::__build_keypath();
&debug_obj($result);
is ( ( not defined($result) ), 1 );

$result = &HP::Support::Configuration::__build_keypath(undef, undef);
&debug_obj($result);
is ( ( not defined($result) ), 1 );

$result = &HP::Support::Configuration::__build_keypath('os_systems', undef);
&debug_obj($result);
is ( defined($result), 1 );

&save_to_configuration(['os_systems1->os_system_styles', [ 'ubuntu', 'centos', 'redhat' ]]);
$result = &HP::Support::Configuration::__build_keypath('os_systems1->os_system_styles', undef);
&debug_obj($result);
is ( defined($result), 1 );

&save_to_configuration(['os_systems2', [ 'windows', 'linux', 'darwin' ]]);
$result = &HP::Support::Configuration::__build_keypath('os_systems2', undef);
&debug_obj($result);
is ( defined($result), 1 );

&debug_obj(&get_configuration());
