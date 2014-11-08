package HP::ProgramManagement;

################################################################################
# Copyright (c) 2013 HP.   All rights reserved
# HP
# HP IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.   BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
# ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
# STANDARD, HP IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
# HP EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.
################################################################################

use warnings;
use strict;
use diagnostics;            

#=============================================================================
BEGIN
  {
    use Exporter();         
                            
    use FindBin;            
    use lib "$FindBin::Bin/..";
                            
    use vars qw(           
                $VERSION
                $is_debug
                $is_init 

                $module_require_list
                $module_request_list

                $broken_install
                $maximum_colspan
				$maximum_colspan_percentage
				
                @ISA
                @EXPORT
               );
    
    $VERSION = 0.99;
 
    @ISA    = qw(Exporter);
    @EXPORT = qw(
                 &initial_setup
                 &provide_help
				 &set_columnspan
				 &show_info
                );

    $module_require_list = {
                            'HP::RegexLib'            => undef,
                            'HP::BasicTools'          => undef,
                            'HP::ArrayTools'          => undef,
                            'HP::Os'                  => undef,
                            'HP::IOTools'             => undef,
                            'HP::Parsers::xmlloader'  => undef,
							'HP::ModuleSupport'       => undef,
							'HP::VersionTools'        => undef,
							'HP::String'              => undef,
                           };

    $module_request_list = {};

    $is_init     = 0;
    $is_debug    = (
		    $ENV{'debug_program_management_pm'} ||
		    $ENV{'debug_hp_modules'} ||
		    $ENV{'debug_all_modules'} || 0
		   );

    $broken_install = 0;
	$maximum_colspan = undef;
	$maximum_colspan_percentage = undef;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
          die "Exiting!\n$@";
        }
      }
    } else {
      my $use_cmd = &load_required_modules( __PACKAGE__, $module_require_list);
      eval "$use_cmd";
    }

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_request_list})) {
        if ( defined($module_request_list->{$usemod}) ) {
          print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
        }
      }
    } else {
      my $use_cmd = &load_required_modules( __PACKAGE__, $module_request_list);
      eval "$use_cmd";
    }

    # Print a message stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
use constant PRE_PADDING     => 4;
use constant POST_PADDING    => 0;
use constant PADDING         => 5;
use constant SUBLINE_PADDING => 5;

#=============================================================================
sub __find_max_length_key($)
  {
    &__print_debug_output("Inside '__find_max_length_key'", __PACKAGE__);

    return 0 if ( ( not defined($_[0]) ) || ( ref($_[0]) !~ m/hash/i ) );

    my $max_length_short_option = 0;
	my $max_length_long_option  = 0;
	
    foreach my $key (keys(%{$_[0]})) {
	  my @pieces = split(/,/,$key,2);
	  $max_length_short_option = length($pieces[0]) if ( length($pieces[0]) > $max_length_short_option);
      $max_length_long_option = length($pieces[1]) if ( length($pieces[1]) > $max_length_long_option );
    }

    return ($max_length_short_option, $max_length_long_option);
  }

#=============================================================================
sub __generate_line($$$$)
  {
    &__print_debug_output("Inside '__generate_line'", __PACKAGE__);

	my $max_length_so = shift;
	my $max_length_lo = shift;
    my $key           = shift;
    my $value         = shift;
    my $value_data    = [];
	
	if ( ref($value) !~ m/array/i ) {
	  $value_data = [ $value, 'O' ];
	} else {
	  $value_data = $value;
	}
	
	if ( scalar(@{$value_data}) == 1 ) { push ( @{$value_data}, 'O' ); }
	
    my $max_length = $max_length_so + $max_length_lo + 1;
    my $result = '';

    return $result if ( not defined($key) );

	$key = &__reformat_option($max_length_so, "$key");
	
    my $pre_spacer  = ' ' x PRE_PADDING;
    my $post_spacer = ' ' x POST_PADDING;

    my $spacer      = ( ( $max_length - length($key) + PADDING ) > -1 ) ? ' ' x ( $max_length - length($key) + PADDING ) : ' ';
    my $entry       = "$pre_spacer$key$spacer  [$value_data->[1]]  ";
    my $total_space = length($entry);

	&__print_debug_output("Entry : $entry");
	&__print_debug_output("Text  : $value_data->[0]");
	my $maximum_line = undef;

    if ( (defined($maximum_colspan)) && (&is_numeric($maximum_colspan))) {
	  $maximum_line = $maximum_colspan;
	}
	
    if ( (defined($maximum_colspan_percentage)) && (&is_numeric($maximum_colspan_percentage)) ) {
	  $maximum_line	= int(($HP::BasicTools::TermIOCols - $total_space) * $maximum_colspan_percentage);
	}
	
	if ( (not defined($maximum_line)) || ($maximum_line <= 1) ) {
	  $maximum_line = $HP::BasicTools::TermIOCols - $total_space;
	}
	
	$value_data->[0] = &make_multiline($value_data->[0], $maximum_line);
    my @multilines = split( /\n/, $value_data->[0]);
    if ( scalar(@multilines) > 1 ) {
      $result = "$entry". join("\n". ' ' x ( $total_space + SUBLINE_PADDING ),@multilines). "$post_spacer\n";
    } else {
      $result = "$entry$value_data->[0]$post_spacer\n" if ( defined($value_data->[0]) );
    }

    return $result;
  }

#=============================================================================
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }       
  }       

#=============================================================================
sub __reformat_option($)
  {
    my $maxlgt = shift;
    my $input  = shift || return;
	
	my @pieces = split(/,/, "$input", 2);

	if (scalar(@pieces) > 1 ) {
	  if ( length($pieces[0]) < 1 ) { $pieces[0] = ' ' x $maxlgt; }
	  if ( length($pieces[0]) < $maxlgt ) { $pieces[0] .= ' ' x ($maxlgt - length($pieces[0])); }
	  return "$pieces[0], $pieces[1]";
	} else {
	  my $spacer = ' ' x $maxlgt;
	  return "$spacer, $pieces[0]";
	}
  }

#=============================================================================
sub initial_setup($)
{
    &__print_debug_output("Inside 'initial_setup'", __PACKAGE__);

    my $proginput = shift;

    if ( ref($proginput) !~ m/hash/i ) {
      &__print_output("Unable to determine specific program components.  Guessing with basic defaults...", __PACKAGE__);
      $proginput = {
					'progname'       => undef,
					'exceptions'     => [],
					'terminate_func' => \&generate_exception,
					'terminate_args' => [ 255 ],
					'xmlfile'        => undef,
                   };
    }

    if ( not defined($proginput->{'progname'}) ) {
      &__print_output("No program name provided!  Using name of 'GENERICPROG'", __PACKAGE__);
      $proginput->{'progname'} = 'genericprog';
    }

    if ( ( not defined($proginput->{'terminate_func'}) ) || ( ref($proginput->{'terminate_func'}) !~ m/code/i ) ) {
      &__print_debug_output("Unable to use non-code reference for program termination.  Using generic termination routine!", __PACKAGE__);
      $proginput->{'terminate_func'} = \&generate_exception;
    }

    if ( ( not defined($proginput->{'terminate_args'}) ) || ( ref($proginput->{'terminate_args'}) !~ m/array/i ) ) {
      &__print_debug_output("Unable to use non-array reference for program termination arguments.  Using generic termination array routine!", __PACKAGE__);
      $proginput->{'terminate_args'} = [ 255 ];
    }

    &add_exception_ids(@{$proginput->{'exceptions'}});
    ( defined($proginput->{'xmlfile'}) ) ? &read_programmatic_xml_file( "$proginput->{'xmlfile'}" ) : &read_programmatic_xml_file();

    my $progname = $proginput->{'progname'};
	my $def_xml_settings = undef;
	
	my @necessary_modules = ();
	my @necessary_module_libs = ();
	
	if ( exists($proginput->{'xmlfile'}) && defined($proginput->{'xmlfile'}) ) {
	  my $def_xml_settings = &extract_xml_section("programs->$progname->global");
	  &raise_exception(
					   'exceptionType' => 'INVALID_CONFIGURATION',
					   'addon_msg'     => "Unable to proper identify XML section for $proginput->{'progname'}",
					   'callback'      => $proginput->{'terminate_func'},
					   'streams'       => [ 'STDERR' ]
					  ) if ( not defined($def_xml_settings) );

	  @necessary_modules     = &extract_contents_as( $def_xml_settings, 'perl_modules->module' );
	  @necessary_module_libs = &extract_contents_as( $def_xml_settings, 'perl_libraries->lib' );
	}
	
	# Handle signals which are used for coordination of the build and should NOT
	# trigger an error condition
    &HP::Os::__prepare_signal_traps($proginput->{'terminate_func'}, $def_xml_settings->{'signal_handling'});

	my $program_information = {};
	if ( exists($proginput->{'xmlfile'}) ) {
	  $program_information  = {
							   'deployment_date'    => $def_xml_settings->{'deployment_date'},
							   'VERSION'            => $def_xml_settings->{'version'},
							   'maintainer'         => $def_xml_settings->{'maintainer'},
							   'email'              => $def_xml_settings->{'email'},
							   'program_input'      => $proginput,
							  };
	} else {
	  $program_information  = $proginput->{'info'};
	}
	
    my $basic_options = {
						 '-h,--help'    => 'Print this message.',
						 '-V,--version' => 'Display version and exit.',
						 '-v,--verbose' => 'Display verbose messages.',
						 '-i,--info'    => 'Display information regarding this script.',
                        };

    &save_to_configuration( 'basic_options', $basic_options );
    &save_to_configuration( 'program_information', $program_information );

	&__print_debug_output("Saved basic information to persistent store...", __PACKAGE__);
	
    if ( scalar(@necessary_modules) ) {
      if ( &get_from_configuration( 'program_information->program_input->add_perl_modules' ) ) {
		push( @necessary_modules, @{&get_from_configuration( 'program_information->program_input->add_perl_modules' )} );
		@necessary_modules = @{&set_unique(\@necessary_modules)};
      }
      &save_to_configuration( 'program_information->program_input->add_perl_modules', \@necessary_modules );
    }

    if ( scalar(@necessary_module_libs) ) {
      if ( &get_from_configuration( 'program_information->program_input->add_perl_sites' ) ) {
		push( @necessary_module_libs, @{&get_from_configuration( 'program_information->program_input->add_perl_sites' )} );
		@necessary_module_libs = @{&set_unique(\@necessary_module_libs)};
      }
      &save_to_configuration( 'program_information->program_input->add_perl_sites', \@necessary_module_libs );
    }

    if ( &get_from_configuration( 'program_information->program_input->debug_on' ) ) {
      $HP::ProgramManagement::is_debug = 1;
      delete($HP::BasicTools::internal_cfg->{'program_information'}->{'program_input'}->{'debug_on'});
    }

    if ( &get_from_configuration( 'program_information->program_input->add_perl_modules' ) ) {
      push( @{$HP::ModuleSupport::module_data->{PERLMOD}}, @{&get_from_configuration( 'program_information->program_input->add_perl_modules' )});
    }

    if ( &get_from_configuration( 'program_information->program_input->add_perl_sites' ) ) {
      push( @{$HP::ModuleSupport::module_data->{PERLSITE}}, @{&get_from_configuration( 'program_information->program_input->add_perl_sites' )});
    }

    my $import_stream = &load_support_modules();

    return ($def_xml_settings, $import_stream);
}

#=============================================================================
sub provide_help(;$)
  {
    &__print_debug_output("Inside 'provide_help'", __PACKAGE__);

    my $errorcode = shift || 0;
 
    my $usage_clause       = &get_from_configuration( 'program_information->program_input->usage_clause' );
    my $description_clause = &make_multiline(&get_from_configuration( 'program_information->program_input->descript_clause' ), int(0.75 * $HP::BasicTools::TermIOCols));
    my $basic_options      = &get_from_configuration( 'basic_options' );
    my $options_clause     = &get_from_configuration( 'program_information->program_input->options_clause' );
    my $example_clause     = &get_from_configuration( 'program_information->program_input->examples_clause' );
    my $other_clauses      = &get_from_configuration( 'program_information->program_input->other_clauses' );
    my $program            = &get_from_configuration( 'program_information->program_input->progname' );

    my $pre_spacer  = ' ' x PRE_PADDING;
    my $post_spacer = ' ' x POST_PADDING;

	if ( defined($options_clause) ) {
	  $options_clause = &HP::RegexLib::__hash_merge($options_clause, $basic_options);
	} else {
	  $options_clause = $basic_options;
	}
    my ($max_length_so, $max_length_lo)  = &__find_max_length_key($options_clause);

	if ( ( not defined($maximum_colspan) ) && ( not defined($maximum_colspan_percentage) ) ) {
	  &set_columnspan( int(($HP::BasicTools::TermIOCols - ($max_length_so + $max_length_lo + 1)) * 0.95) );
	}

    my $options  = '';
    if ( defined($options_clause) ) {
      foreach my $key (sort { "\L$a" cmp "\L$b" }(keys(%{$options_clause}))) {
		$options .= &__generate_line( $max_length_so, $max_length_lo, "$key", $options_clause->{$key} );
      }
    }

    my $examples = '';
    if ( defined($example_clause) ) {
      foreach my $key (@{$example_clause}) {
		$examples .= "$pre_spacer$program $key\n";
      }
    }

	my $description = '';
    if ( defined($description_clause) ) {
      foreach my $key (split("\n",$description_clause)) {
		$description .= "$pre_spacer$key\n";
      }
    }

    my $others = '';
    if ( defined($other_clauses) ) {
      foreach my $key (sort(keys(%{$other_clauses}))) {
		if ( exists($other_clauses->{"$key"}->{'title'}) ) {
		  $others .= "\n$other_clauses->{$key}->{'title'}\n\n";
		} else {
		  next;
		}
		if ( exists($other_clauses->{"$key"}->{'content'}) ) {
		  foreach my $value (@{$other_clauses->{"$key"}->{'content'}}) {
			$others .= "$pre_spacer$value\n";
		  }
		  $others .= "\n";
		}
      }
    }

    if ( defined($usage_clause) ) {
    print STDOUT <<EOT;

Usage:

    $program $usage_clause
EOT
;
    }

    if ( defined($description_clause) ) {
    print STDOUT <<EOT;

Description:

$description
EOT
;
    }

    if ( defined($options_clause) ) {
    print STDOUT <<EOT;

Options:

$options
EOT
;
    }

    if ( defined($example_clause) ) {
    print STDOUT <<EOT;

Examples:

$examples
EOT
;
    }

    if ( defined($other_clauses) ) {
    print STDOUT <<EOT;
$others
EOT
;
    }

    my $termination = &get_from_configuration( 'program_information->program_input->terminate_func' );
	if ( ref($termination) =~ m/code/i ) {
	  &{$termination}($errorcode);
	}
  }

#=============================================================================
sub set_columnspan($)
  {
     my $input = shift || 1;
	 if ( not &valid_string($input) || $input < 0 ) { $input = 1; }
	 
	 if ( $input > 1 ) { $maximum_colspan = $input; }
	 else { $maximum_colspan_percentage = $input; }
	 
  }

#=============================================================================
sub show_info(;$)
  {
    &__print_debug_output("Inside 'show_info'", __PACKAGE__);

    print STDERR "\n".uc(&get_from_configuration( 'program_information->program_input->progname' )).":\n\n";

	my $tlv = shift || "$ENV{'CSLBLD'}";
    print STDERR "\tTools version                        : ". &get_my_version($tlv)."\n";
    print STDERR "\tInternal program version             : ". &get_from_configuration( 'program_information->VERSION' ) ."\n";
    print STDERR "\tDeployment date                      : ". &get_from_configuration( 'program_information->deployment_date' ) ."\n";
    print STDERR "\tMaintainer                           : ". &get_from_configuration( 'program_information->maintainer' ). "\n";
    print STDERR "\tMaintainer Email                     : ". &get_from_configuration( 'program_information->email' ) ."\@hp.com\n\n";
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
