#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Base::Constants');
	use_ok('HP::Support::Object');
    use_ok('HP::Support::Object::Tools');
  }

my $objtemplate = { 'one' => undef, 'two' => 2, 'subobj' => 'c__HP::XMLObject__' };
my $obj = &create_object($objtemplate);
is ( defined($obj), TRUE );

&debug_obj($obj);

&HP::Support::Object::__cleanup_internals($obj);

&debug_obj($obj);
