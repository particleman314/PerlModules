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
	use_ok('HP::Support::Configuration::Constants');
	use_ok('HP::CheckLib');
  }

my ($result, $is_changed) = &HP::Support::Configuration::__substitute_proc('[HP::Support::Os::get_pid]');
is ( defined($result), 1 );
is ( &is_integer($result) eq TRUE, 1 );
is ( $is_changed eq TRUE, 1 );

&debug_obj($result);

($result, $is_changed) = &HP::Support::Configuration::__substitute_proc('HP::Support::Os::get_pid');
is ( defined($result), 1 );
is ( $result eq 'HP::Support::Os::get_pid', 1 );
is ( $is_changed eq FALSE, 1 );

&debug_obj($result);