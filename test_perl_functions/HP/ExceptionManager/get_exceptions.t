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
    use_ok('HP::ExceptionManager');
	use_ok('HP::Exception::Constants');
  }

my $exception_data = &HP::ExceptionManager::get_exceptions();
is ( scalar(keys(%{$exception_data})) == 0, 1 );

eval "use HP::Array::Tools;";

$exception_data = &HP::ExceptionManager::get_exceptions();
is ( scalar(keys(%{$exception_data})) > 0, 1 );

my $numarray_exceptions = scalar(keys(%{$exception_data->{'array'}}));
is ( $numarray_exceptions > 0, 1 );

my $unregistered_exception_data = &HP::ExceptionManager::get_exceptions(EXCEPTION_UNREGISTERED);
is ( scalar(keys(%{$unregistered_exception_data})) > 0, 1 );

&register_exception('no_array_object');
$exception_data = &HP::ExceptionManager::get_exceptions(EXCEPTION_UNREGISTERED);
is ( scalar(keys(%{$exception_data})) > 0, 1 );

my $new_numarray_exceptions = scalar(keys(%{$exception_data->{'array'}}));
is ( $new_numarray_exceptions > 0, 1 );
is ( $new_numarray_exceptions < $numarray_exceptions, 1 );

debug_obj($exception_data);
