package HP::Support::ProgramManagement;

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
                            'HP::Constants'                             => undef,
                            'HP::Support::Base'                         => undef,
							'HP::Support::Base::Constants'              => undef,
							'HP::Support::Hash'                         => undef,
							'HP::Support::Module'                       => undef,
							'HP::Support::Configuration'                => undef,
							'HP::Support::Screen'                       => undef,
							'HP::Support::Object::Tools'                => undef,
							
							'HP::CheckLib'                              => undef,
                            'HP::Array::Tools'                          => undef,
							
							'HP::Exception::Tools'                      => undef,
                            'HP::Os'                                    => undef,
							'HP::String'                                => undef,
							
							'HP::Support::ProgramManagement::Constants' => undef,
                           };

    $module_request_list = {};

    $is_init     = 0;
    $is_debug    = (
		    $ENV{'debug_programmanagement_pm'} ||
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
my $local_true    = TRUE;
my $local_false   = FALSE;

my $local_pass    = PASS;

#=============================================================================
sub __find_max_length_key($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my ($max_length_short_option, $max_length_long_option) = ( undef, undef );
	
    goto __END_OF_SUB if ( not defined($_[0]) );
	goto __END_OF_SUB if ( ref($_[0]) !~ m/hash/i );

    $max_length_short_option = 0;
	$max_length_long_option  = 0;
	
    foreach my $key (keys(%{$_[0]})) {
	  my $final = [ undef, undef ];
	  my @pieces = split(/,/,$key,2);
	  &__print_debug_output("Components :: @pieces", __PACKAGE__) if ( $is_debug );
	  
	  if ( &str_starts_with($pieces[0], [ '--' ]) eq TRUE ) {
	    $final->[1] = $pieces[0];
		$final->[0] = $pieces[1] if ( defined($pieces[1]) );
	  } else {
	    $final = \@pieces;
	  }
	  
	  if ( defined($final->[0]) ) {
	    $final->[0] = &deblank($final->[0]);
	    $final->[0] =~ s/\-//;
	  }
	  
	  if ( defined($final->[1]) ) {
	    $final->[1] = &deblank($final->[1]);
	    $final->[1] =~ s/\-\-//;
	  }
	  
	  $max_length_short_option = length($final->[0]) if ( defined($final->[0]) && length($final->[0]) > $max_length_short_option);
      $max_length_long_option  = length($final->[1]) if ( defined($final->[1]) && length($final->[1]) > $max_length_long_option );
    }

  __END_OF_SUB:
    return ($max_length_short_option, $max_length_long_option);
  }

#=============================================================================
sub __generate_line($$$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $max_length_so = $_[0];
	my $max_length_lo = $_[1];
    my $key           = $_[2];
    my $value         = $_[3];
    my $value_data    = [];
	
	if ( ref($value) !~ m/^array/i ) {
	  $value_data = [ $value, 'O' ];
	} else {
	  $value_data = $value;
	}
	
	if ( scalar(@{$value_data}) == 1 ) { push ( @{$value_data}, 'O' ); }
	
    my $max_length = $max_length_so + $max_length_lo + 1;
    my $result     = '';

    goto __END_OF_SUB if ( not defined($key) );

	$key = &__reformat_option($max_length_so, "$key");
	
    my $pre_spacer  = ' ' x PRE_PADDING;
    my $post_spacer = ' ' x POST_PADDING;

    my $spacer      = ( ( $max_length - length($key) + PADDING ) > -1 ) ? ' ' x ( $max_length - length($key) + PADDING ) : ' ';
    my $entry       = "$pre_spacer$key$spacer  [$value_data->[1]]  ";
    my $total_space = length($entry);

	&__print_debug_output("Entry : $entry") if ( $is_debug );
	&__print_debug_output("Text  : $value_data->[0]") if ( $is_debug );
	my $maximum_line = undef;

    if ( (defined($maximum_colspan)) && (&is_numeric($maximum_colspan) eq $local_true)) {
	  $maximum_line = $maximum_colspan;
	}
	
    if ( (defined($maximum_colspan_percentage)) && (&is_numeric($maximum_colspan_percentage) eq $local_true) ) {
	  $maximum_line	= int(($HP::Support::Screen::TermIOCols - $total_space) * $maximum_colspan_percentage);
	}
	
	if ( (not defined($maximum_line)) || ($maximum_line <= 1) ) {
	  $maximum_line = $HP::Support::Screen::TermIOCols - $total_space;
	}
	
	$value_data->[0] = &make_multiline($value_data->[0], $maximum_line);
    my @multilines = split( /\n/, $value_data->[0] );
    if ( scalar(@multilines) > 1 ) {
      $result = "$entry". join("\n". ' ' x ( $total_space + SUBLINE_PADDING ),@multilines). "$post_spacer\n";
    } else {
      $result = "$entry$value_data->[0]$post_spacer\n" if ( defined($value_data->[0]) );
    }

  __END_OF_SUB:
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
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $maxlgt = shift;
    my $input  = shift || return;
	
	my @pieces = split(/,/, "$input", 2);

	my $final = [ undef, undef ];
	
	if ( &str_starts_with($pieces[0], [ '--' ]) eq $local_true ) {
	  $final->[1] = $pieces[0];
      $final->[0] = $pieces[1] if ( defined($pieces[1]) );
	} else {
	  $final = \@pieces;
	}
	  
	if ( defined($final->[0]) ) {
	  $final->[0] = &deblank($final->[0]);
	}
	  
	if ( defined($final->[1]) ) {
	  $final->[1] = &deblank($final->[1]);
	}

	if (scalar(@pieces) > 1 ) {
	  if ( not defined($final->[0]) || length($final->[0]) < 1 ) { $final->[0] = ' ' x $maxlgt; }
	  if ( defined($final->[0]) && length($final->[0]) < $maxlgt ) { $final->[0] .= ' ' x ($maxlgt - length($final->[0])); }
	  return "$pieces[0], $pieces[1]";
	} else {
	  my $spacer = ' ' x $maxlgt;
	  return "$spacer, $pieces[0]";
	}
  }

#=============================================================================
sub __set_debug($)
  {
    if ( $_[0] eq $local_true ) {
	  $is_debug = $local_true;
	  eval "use Data::Dumper;";
	  eval "\$Data::Dumper::Sortkeys = 1;";
	}
  }
  
#=============================================================================
sub build_interpretation_array_for_getopt($)
  {
    my $input_decoder = $_[0];
	my $root = 'derived_data';

	if ( not defined($input_decoder) ) {
	  &save_to_configuration({'data' => [ "$root->configuration", [] ]});
	  &__print_output("No argument decoder defined from help-screen due to NO DATA!", WARN);
	  return;
	}
	
	if ( ref($input_decoder) !~ m/hash/i ) {
	  &save_to_configuration({'data' => [ "$root->configuration", [] ]});
	  &__print_output("Improper argument decoder defined from help-screen!", WARN);
	  return;
	}
	
	my $interpretor = &create_object('c__HP::Array::Set__');
	my $defaults    = {};
	
	my $l2s = {};
	my $s2l = {};
	
	foreach my $key (keys(%{$input_decoder})) {
	  my @pieces = split(/,/, "$key", 2);

	  my $final = [ undef, undef ];
	
	  if ( &str_starts_with($pieces[0], [ '--' ]) eq $local_true ) {
	    $final->[1] = $pieces[0];
        $final->[0] = $pieces[1] if ( defined($pieces[1]) );
	  } else {
	    $final = \@pieces;
	  }

	  my $isolated_short_option = $final->[0]; 
	  my $isolated_long_option  = $final->[1];
	  
	  my $association   = $input_decoder->{"$key"};
	  my $default_value = undef;	   
	  my $type_marker   = '';
	  $type_marker      = $association->[2] if ( scalar(@{$association}) >= 3 );
	  
	  if ( defined($association->[3]) ) {
	    $default_value = $association->[3];
	  } else {
	    if ( $type_marker =~ m/\@/ ) {
		  $default_value = [];
		}
	  }
	  
	  if ( defined($isolated_short_option) ) {
	    $isolated_short_option =~ s/=(.*)//;
		$isolated_short_option =~ s/^\-//;
	    $interpretor->push_item("$isolated_short_option$type_marker");
	    $defaults->{$isolated_short_option} = $default_value;
	  }
	  
	  if ( defined($isolated_long_option) ) {
	    $isolated_long_option  =~ s/=(.*)//;
		$isolated_long_option =~ s/^\-\-//;
	    $interpretor->push_item("$isolated_long_option$type_marker");
	    $defaults->{$isolated_long_option} = $default_value;
	  }

	  if ( defined($isolated_short_option) && defined($isolated_long_option) ) {
	    $l2s->{$isolated_long_option}  = $isolated_short_option;
		$s2l->{$isolated_short_option} = $isolated_long_option;
	  } elsif ( defined($isolated_short_option) && ( not defined($isolated_long_option) ) ) {
		$s2l->{$isolated_short_option} = undef;
	  } elsif ( defined($isolated_long_option) && ( not defined($isolated_short_option) ) ) {
	    $l2s->{$isolated_long_option}  = undef;
	  }
	}
	
	my $options = $interpretor->get_elements();
	
	&save_to_configuration({'data' => [ "$root->configuration", $options ]});
	&save_to_configuration({'data' => [ "$root->configuration_defaults", $defaults ]});
	&save_to_configuration({'data' => [ "$root->configuration_translations", [ $s2l, $l2s ] ]});
	
	return;
  }
  
#=============================================================================
sub initial_setup($)
{
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $proginput = $_[0];

    if ( ref($proginput) !~ m/hash/i ) {
      &__print_output("Unable to determine specific program components.  Guessing with basic defaults...", __PACKAGE__);
      $proginput = {
					'progname'       => undef,
					'exceptions'     => [],
					'terminate_func' => \&raise_exception, # Need to provide this from appropriate module
					'terminate_args' => [ 255 ],
					'xmlfile'        => undef,
                   };
    }

    if ( not defined($proginput->{'progname'}) ) {
      &__print_output("No program name provided!  Using name of 'GENERICPROG'", __PACKAGE__);
      $proginput->{'progname'} = 'genericprog';
    }

    if ( ( not defined($proginput->{'terminate_func'}) ) || ( ref($proginput->{'terminate_func'}) !~ m/code/i ) ) {
      &__print_debug_output("Unable to use non-code reference for program termination.  Using generic termination routine!", __PACKAGE__) if ( $is_debug );
      $proginput->{'terminate_func'} = \&raise_exception;  # Need to provide this from appropriate module
    }

    if ( ( not defined($proginput->{'terminate_args'}) ) || ( ref($proginput->{'terminate_args'}) !~ m/array/i ) ) {
      &__print_debug_output("Unable to use non-array reference for program termination arguments.  Using generic termination array routine!", __PACKAGE__);
      $proginput->{'terminate_args'} = [ 255 ];
    }

    my $progname = $proginput->{'progname'};
	my $def_xml_settings = undef;
	
	my @necessary_modules = ();
	my @necessary_module_libs = ();
		
	# Handle signals which are used for coordination of the build and should NOT
	# trigger an error condition
    &HP::Os::__prepare_signal_traps($proginput->{'terminate_func'}, $def_xml_settings->{'signal_handling'});

	my $program_information = $proginput->{'info'};
	
    my $basic_options = {
						 '-h,--help'    => [ 'Print this message.', OPTIONAL, '', $local_false ],
						 '-V,--version' => [ 'Display version and exit.', OPTIONAL, '', $local_false ],
						 '-v,--verbose' => [ 'Display verbose messages.', OPTIONAL, '', $local_false  ],
						 '-i,--info'    => [ 'Display information regarding this script.', OPTIONAL, '', $local_false ],
                        };

    &save_to_configuration({'data' => [ 'basic_options', $basic_options ]} );
	
	if ( exists($program_information->{'program_input'}->{'options_clause'}) ) {
	  $program_information->{'program_input'}->{'options_clause'} = &HP::Support::Hash::__hash_merge($program_information->{'program_input'}->{'options_clause'}, $basic_options);
	} else {
	  $program_information->{'program_input'}->{'options_clause'} = $basic_options;
	}
	
    &save_to_configuration({'data' => [ 'program_information', $program_information ]});

	&__print_debug_output("Saved basic information to persistent store...", __PACKAGE__) if ( $is_debug );
	
    #if ( scalar(@necessary_modules) ) {
    #  if ( &get_from_configuration( 'program_information->program_input->add_perl_modules' ) ) {
	#	push( @necessary_modules, @{&get_from_configuration( 'program_information->program_input->add_perl_modules' )} );
	#	@necessary_modules = @{&set_unique(\@necessary_modules)};
    #  }
    #  &save_to_configuration( 'program_information->program_input->add_perl_modules', \@necessary_modules );
    #}

    #if ( scalar(@necessary_module_libs) ) {
    #  if ( &get_from_configuration( 'program_information->program_input->add_perl_sites' ) ) {
	#	push( @necessary_module_libs, @{&get_from_configuration( 'program_information->program_input->add_perl_sites' )} );
	#	@necessary_module_libs = @{&set_unique(\@necessary_module_libs)};
    #  }
    #  &save_to_configuration( 'program_information->program_input->add_perl_sites', \@necessary_module_libs );
    #}

    if ( &get_from_configuration( 'program_information->program_input->debug_on' ) ) {
      $HP::Support::ProgramManagement::is_debug = $local_true;
	  #&turn_on_debugging();
      delete($HP::Support::Configuration::internal_cfg->{'program_information'}->{'program_input'}->{'debug_on'});
    }

	&build_interpretation_array_for_getopt($program_information->{'program_input'}->{'options_clause'});
    #if ( &get_from_configuration( 'program_information->program_input->add_perl_modules' ) ) {
    #  push( @{$HP::ModuleSupport::module_data->{PERLMOD}}, @{&get_from_configuration( 'program_information->program_input->add_perl_modules' )});
    #}

    #if ( &get_from_configuration( 'program_information->program_input->add_perl_sites' ) ) {
    #  push( @{$HP::ModuleSupport::module_data->{PERLSITE}}, @{&get_from_configuration( 'program_information->program_input->add_perl_sites' )});
    #}

    #my $import_stream = &load_support_modules();
	my $import_stream = undef;
	
    return ($def_xml_settings, $import_stream);
}

#=============================================================================
sub provide_help(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $errorcode = $_[0] || $local_pass;
 
    my $usage_clause       = &get_from_configuration( 'program_information->program_input->usage_clause' );
    my $description_clause = &make_multiline(&get_from_configuration( 'program_information->program_input->descript_clause' ), int(0.75 * $HP::Support::Screen::TermIOCols));
    my $options_clause     = &get_from_configuration( 'program_information->program_input->options_clause' );
    my $example_clause     = &get_from_configuration( 'program_information->program_input->examples_clause' );
    my $other_clauses      = &get_from_configuration( 'program_information->program_input->other_clauses' );
    my $program            = &get_from_configuration( 'program_information->program_input->progname' );

    my $pre_spacer  = ' ' x PRE_PADDING;
    my $post_spacer = ' ' x POST_PADDING;

	my ($max_length_so, $max_length_lo) = (0, 0);
	if ( defined($options_clause) ) {
      ($max_length_so, $max_length_lo)  = &__find_max_length_key($options_clause);

	  if ( ( not defined($maximum_colspan) ) && ( not defined($maximum_colspan_percentage) ) ) {
	    &set_columnspan( int(($HP::Support::Screen::TermIOCols - ($max_length_so + $max_length_lo + 1)) * 0.95) );
	  }
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
	&{$termination}($errorcode) if ( ref($termination) =~ m/code/i );
	return;
  }

#=============================================================================
sub set_columnspan($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $input = $_[0] || 1;
	if ( ( &valid_string($input) eq $local_false ) || &is_integer($input) eq $local_false || $input < 0 ) { $input = 1; }
	 
	if ( $input > 1 ) { $maximum_colspan = $input; }
	else { $maximum_colspan_percentage = $input; } 
  }

#=============================================================================
sub show_info(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $unit = &get_from_configuration( 'program_information' );
	
	my $progname = &get_from_configuration( 'program_information->program_input->progname' );
    print STDERR "\n".uc($progname).":\n\n" if ( defined($progname) );

	my $tlv = $_[0] || $ENV{'VERSION'} || $main::VERSION || '1.0';
	my $vobj = &create_object('c__HP::VersionObject__');
	$vobj->set_version($tlv);
	
    print STDERR "\tTools version                        : ". $vobj->get_version()."\n";
	if ( defined($unit) ) {
      print STDERR "\tInternal program version             : ". &get_from_configuration( 'program_information->VERSION' ) ."\n";
      print STDERR "\tDeployment date                      : ". &get_from_configuration( 'program_information->deployment_date' ) ."\n";
      print STDERR "\tMaintainer                           : ". &get_from_configuration( 'program_information->maintainer' ) ."\n";
      print STDERR "\tMaintainer Email                     : ". &get_from_configuration( 'program_information->email' ) ."\@hp.com\n\n";
    }
  }
#=============================================================================
&__initialize();

#=============================================================================
1;