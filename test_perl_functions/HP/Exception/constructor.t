#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Exception');
  }

my $obj = HP::Exception->new();
is ( defined($obj), 1 );

$obj->set_error_code(56);
$obj->set_message('This is a test');
$obj->add_message('Another_line');
$obj->add_handle('One');
$obj->add_handle('Two');
$obj->add_handle(undef);
$obj->add_handle(undef);

&debug_obj($obj);
