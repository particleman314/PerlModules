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

&save_to_configuration(['way->too->deep', 'wow']);

my ($result, $is_changed) = &HP::Support::Configuration::__substitute_text('way->too->deep');
is ( defined($result), 1 );
is ( $result eq 'way->too->deep', 1 );
is ( $is_changed eq FALSE, 1 );

&debug_obj($result);

($result, $is_changed) = &HP::Support::Configuration::__substitute_text('{{{way->too->deep}}}','{','}');
is ( defined($result), 1 );
is ( $result eq '{{wow}}', 1 );
is ( $is_changed eq TRUE, 1 );

&debug_obj($result);

($result, $is_changed) = &HP::Support::Configuration::__substitute_text('{{{way->too->deep}}}','{{','}}');
is ( defined($result), 1 );
is ( $result eq '{wow}', 1 );
is ( $is_changed eq TRUE, 1 );

&debug_obj($result);
