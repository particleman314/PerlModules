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

eval "use HP::Array::Tools;";

my $exception_data = &HP::ExceptionManager::get_exceptions(EXCEPTION_UNREGISTERED);
is ( scalar(keys(%{$exception_data})) > 0, 1 );

&debug_obj($exception_data);

my $numarray_exceptions = scalar(keys(%{$exception_data->{'array'}}));
is ( $numarray_exceptions > 0, 1 );

&register_exception('index_outofbounds');
&register_exception('no_such_element');

$exception_data = &HP::ExceptionManager::get_exceptions(EXCEPTION_UNREGISTERED);
my $new_numarray_exceptions = scalar(keys(%{$exception_data->{'array'}}));
is ( $new_numarray_exceptions > 0, 1 );
is ( ($numarray_exceptions - $new_numarray_exceptions) eq 2, 1 );

&debug_obj($exception_data);

my $all_exception_data = &HP::ExceptionManager::get_exceptions();
&debug_obj($all_exception_data);
