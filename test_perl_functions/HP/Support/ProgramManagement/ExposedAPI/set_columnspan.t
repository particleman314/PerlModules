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

my $program_name = 'TEST';

my $proginput = {
					'progname'       => undef,
					'exceptions'     => [],
					'terminate_func' => \&raise_exception,
					'terminate_args' => [ 255 ],
					'xmlfile'        => undef,
                   };
				   
my $program_information  = $proginput->{'info'};

&save_to_configuration( 'basic_options', $basic_options );
&save_to_configuration( 'program_information', $program_information );
&save_to_configuration( 'program_information->program_input->progname', $program_name);

delete($ENV{'CSLBLD'});

&show_info();
