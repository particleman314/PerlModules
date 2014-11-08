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

my $result = &HP::Support::Configuration::__do_substitution();
&debug_obj($result);
is ( ( not defined($result) ), 1 );

$result = &HP::Support::Configuration::__do_substitution('{{{hello}}}','hello',1,'','','{{{','}}}');
&debug_obj($result);
is ( defined($result), 1 );
is ( $result eq 1, 1 );

$result = &HP::Support::Configuration::__do_substitution('blah{{{hello}}}blah','hello',1,'','','{{{','}}}');
&debug_obj($result);
is ( defined($result), 1 );
is ( $result eq 'blah1blah', 1 );
