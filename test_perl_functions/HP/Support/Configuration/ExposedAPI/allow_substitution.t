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

my ($result, $changed) = &allow_substitution();
is ( (not defined($result)), 1 );

my $content = '${hello}';
# Default markers are {{{ }}}
($result, $changed) = &allow_substitution($content);
is ( defined($result), 1 );
is ( $result eq $content, 1 );

$content = '{{{hello}}';
($result, $changed) = &allow_substitution($content);
is ( defined($result), 1 );
is ( $result eq $content, 1 );

$content = '{hello}}}';
($result, $changed) = &allow_substitution($content);
is ( defined($result), 1 );
is ( $result eq $content, 1 );

$main::hello = 1;

$content = '{{{hello}}}';
( $result, $changed ) = &allow_substitution($content);
is ( defined($result), 1 );
is ( $result eq $main::hello, 1 );

$content = '${hello}';
($result, $changed) = &allow_substitution($content, '${', '}');
is ( defined($result), 1 );
is ( $result eq $main::hello, 1 );

$main::goodbye = 2;

$content = [
            '${hello}',
			'${goodbye}',
			'${badconversion}',
		   ];
($result, $changed) = &allow_substitution($content, '${', '}');
is ( defined($result), 1 );
is ( $result->[0] eq $main::hello, 1 );
is ( $result->[1] eq $main::goodbye, 1 );
is ( $result->[2] eq '', 1 );

$content = '[ HP::Support::Os::get_pid ]';
($result, $changed) = &allow_substitution($content);
is ( defined($result), 1 );
is ( &is_integer($result) eq TRUE, 1 );

&debug_obj($content);
&debug_obj($result);
