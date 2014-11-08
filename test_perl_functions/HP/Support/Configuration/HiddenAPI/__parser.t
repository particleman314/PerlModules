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

my ( $b, $m, $e, $match ) = &HP::Support::Configuration::__parser('way->too->deep', '{','}');
is ( ( not defined($b) ), 1 );
is ( ( not defined($m) ), 1 );
is ( ( not defined($e) ), 1 );
is ( $match eq FALSE, 1 );

&debug_obj([$b, $m, $e, $match]);

( $b, $m, $e, $match ) = &HP::Support::Configuration::__parser('{{way->too->deep}}', '{{{','}}}');
is ( ( not defined($b) ), 1 );
is ( ( not defined($m) ), 1 );
is ( ( not defined($e) ), 1 );
is ( $match eq FALSE, 1 );

&debug_obj([$b, $m, $e, $match]);

( $b, $m, $e, $match ) = &HP::Support::Configuration::__parser('{{{way->too->deep}}}', '{','}');
is ( $b eq '{{', 1 );
is ( $m eq 'way->too->deep', 1 );
is ( $e eq '}}', 1 );
is ( $match eq TRUE, 1 );

&debug_obj([$b, $m, $e, $match]);

( $b, $m, $e, $match ) = &HP::Support::Configuration::__parser('{{{way->too->deep}}}', '{{','}}');
is ( $b eq '{', 1 );
is ( $m eq 'way->too->deep', 1 );
is ( $e eq '}', 1 );
is ( $match eq TRUE, 1 );

&debug_obj([$b, $m, $e, $match]);

( $b, $m, $e, $match ) = &HP::Support::Configuration::__parser('{{{way->too->deep}}}', '{{{','}}}');
is ( $b eq '', 1 );
is ( $m eq 'way->too->deep', 1 );
is ( $e eq '', 1 );
is ( $match eq TRUE, 1 );

&debug_obj([$b, $m, $e, $match]);
