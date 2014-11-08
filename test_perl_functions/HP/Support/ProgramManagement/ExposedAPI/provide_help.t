#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok('HP::Constants');
	use_ok('HP::Support::Configuration');
	use_ok('HP::Support::ProgramManagement');
  }

my $basic_options = {
						 '-h,--help'    => 'Print this message.',
						 '-V,--version' => 'Display version and exit.',
						 '-v,--verbose' => 'Display verbose messages.',
						 '-i,--info'    => 'Display information regarding this script.',
                        };

&save_to_configuration( 'basic_options', $basic_options );

&provide_help();
