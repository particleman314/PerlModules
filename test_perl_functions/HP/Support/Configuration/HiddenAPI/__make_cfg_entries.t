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

my ($keys, $values) = &HP::Support::Configuration::__make_cfg_entries('way->too->deep', 'wow');
is ( defined($keys), 1 );
is ( defined($values), 1 );

is ( scalar(@{$keys}) == 1, 1 );
is ( scalar(@{$values}) == 1, 1 );

&debug_obj($keys);
&debug_obj($values);

($keys, $values) = &HP::Support::Configuration::__make_cfg_entries(('way->too->deep', 'wow'));
is ( defined($keys), 1 );
is ( defined($values), 1 );

is ( scalar(@{$keys}) == 1, 1 );
is ( scalar(@{$values}) == 1, 1 );

&debug_obj($keys);
&debug_obj($values);

($keys, $values) = &HP::Support::Configuration::__make_cfg_entries({'way->too->deep' => 'wow'});
is ( defined($keys), 1 );
is ( defined($values), 1 );

is ( scalar(@{$keys}) == 1, 1 );
is ( scalar(@{$values}) == 1, 1 );

&debug_obj($keys);
&debug_obj($values);