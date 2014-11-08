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

&save_to_configuration({'data' => [ 'way->too->deep', 'wow' ]});
my $result = &HP::Support::Configuration::__is_configuration_cached('way->too->deep');
is ( defined($result), 1 );
is ( $result eq FALSE, 1 );

