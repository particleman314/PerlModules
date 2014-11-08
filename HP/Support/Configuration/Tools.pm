package HP::Support::Configuration::Tools;

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
    use lib "$FindBin::Bin/../../..";

    use vars qw(
                $VERSION
                $is_debug
                $is_init

                $module_require_list
                $module_request_list

                $broken_install

                $default_separator
                $silent

                @ISA
                @EXPORT
               );

    @ISA    = qw(Exporter);
    @EXPORT = qw(
				 &load_properties
                 &manage_cla
				 &manage_options
                );

    $module_require_list = {
                            'File::Copy'         => undef,
                            'Getopt::Long'       => undef,
                            'Config::General'    => undef,
							'Config::IniFiles'   => undef,
							'Config::Properties' => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Os'              => undef,
							'HP::Support::Configuration'   => undef,
                            'HP::String'                   => undef,
                            'HP::Array::Tools'             => undef,
                            'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
                           };

    $module_request_list = {
                            'Tie::IxHash'          => undef,
			               };

    $VERSION           = 0.95;
    $default_separator = ' ';
    $silent            = 0;

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_support_configuration_tools_pm'} ||
                 $ENV{'debug_support_configuration_modules'} ||
                 $ENV{'debug_support_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

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
use constant CONFIG_PASS          => 0;
use constant CONFIG_FAIL_NO_FILE  => -1;
use constant CONFIG_FAIL_NO_DATA  => -2;
use constant CONFIG_FAIL_NOT_HASH => -3;

#=============================================================================
my $local_true    = TRUE;
my $local_false   = FALSE;

#=============================================================================
sub __initialize()
  {
    if ( $is_init eq $local_false ) {
      $is_init = $local_true;
      print STDERR "INIITALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
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
sub load_properties($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $result = CONFIG_PASS;

    my $fn       = $_[0];
    my $prop_ref = $_[1];
    my $prop_key = $_[2] || 'properties';
	
	
    &__print_debug_output("Testing filename <$fn>\n", __PACKAGE__) if ( $is_debug );
    if ( &does_file_exist("$fn") eq FALSE ) {
	  $result = CONFIG_FAIL_NO_FILE;
	  goto __END_OF_SUB;
	}

    &__print_debug_output("File exists <$fn>, now checking for data to parse\n", __PACKAGE__) if ( $is_debug );
	
	open my $fh, "<", "$fn";
	if ( defined($fh) ) {
	    $prop_ref->{$prop_key} = new Config::Properties();
		$prop_ref->{$prop_key}->load($fh);
		#&allow_substitution($prop_ref, $prop_key);
	}
	close $fh;
    &__print_debug_output("Properties file parsed -->\n".Dumper($prop_ref), __PACKAGE__) if ( $is_debug );

  __END_OF_SUB:
    return $result;
  }
  
#=============================================================================
sub manage_cla(;$$$$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $command_line_option_ref      = &get_from_configuration('program->user_arguments');
    my $getopt_array_interpretation  = &get_from_configuration('derived_data->configuration');
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'long_options',  undef,
	                                        'cla_coderef',   undef,
											'remove_slo',    \&is_integer,
	                                        'usage_coderef', undef,
                                            'interpret_map', undef,	], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[0];
	}

    my $getopt_long_options          = $inputdata->{'long_options'}  || [];
    my $user_cla_coderef             = $inputdata->{'cla_coderef'}   || undef;
    my $remove_single_letter_options = $inputdata->{'remove_slo'}    || $local_false;
    my $user_usage_coderef           = $inputdata->{'usage_coderef'} || undef;
    my $getopt_interpretation_map    = $inputdata->{'interpret_map'} || {};

    $getopt_array_interpretation = [] if ( ref($getopt_array_interpretation) !~ m/^array/i );

    if ( &set_contains('auto_version',$getopt_long_options) eq $local_false ) {
      push (@{$getopt_long_options},'auto_version');
    }

    &Getopt::Long::Configure( @{$getopt_long_options} )
      if ( defined($getopt_long_options) );
	
    # Process all the command line variables into a hash
    my $rval = GetOptions(
			  $command_line_option_ref,
			  @{$getopt_array_interpretation}
			 ) || $local_false;

    if ( ref($user_usage_coderef) =~ m/code/i ) {
      if ( $rval eq $local_false ) { 
	    &__print_output("Problem with parsing arguments!!", WARN);
	    &{$user_usage_coderef}();
      }
    }

	if ( $is_debug ) {
	  &__print_debug_output("Processed command line options : ");
	  &__print_debug_output(Dumper($command_line_option_ref));
	}
	
    # Allow for specific processing
    &{$user_cla_coderef}($command_line_option_ref)
      if ( ref($user_cla_coderef) =~ m/code/i );

    # Remove undefined options
    foreach my $key (keys(%{$command_line_option_ref})) {
      if ( not defined($command_line_option_ref->{$key}) ) {
	    delete($command_line_option_ref->{$key});
      }
    }

    # Ensure the short option cases get translated to the
    # long version for the same option
    foreach my $key (keys(%{$getopt_interpretation_map})) {
      my $short_options = $getopt_interpretation_map->{$key};
      $short_options = &convert_to_array($short_options) if ( ref($short_options) !~ m/^array/i );
      foreach my $short (@{$short_options}) {
	    if ( defined($command_line_option_ref->{$short}) ) {
	      $command_line_option_ref->{$key} = $command_line_option_ref->{$short};
	    }
      }
    }

    # Remove the short options if requested
    if ( $remove_single_letter_options ) {
      foreach my $key (keys(%{$command_line_option_ref})) {
	    if ( length($key) == 1 ) { delete($command_line_option_ref->{$key}); }  # This needs to be revisited!
      }
    }

    # Call the help function if help was found in the command line arguments
    &{$user_usage_coderef} if ( (ref($user_usage_coderef) =~ m/code/i) &&
				                ($command_line_option_ref->{'help'}) );
	return;
  }

#=============================================================================
sub manage_options()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $argsref          = &get_from_configuration('program->user_arguments');
	my $translation_maps = &get_from_configuration('derived_data->configuration_translations');
	
	my $l2s = $translation_maps->[1];
	
	my $default_vals = &get_from_configuration('derived_data->configuration_defaults');

	# Shortcoming is the ability to ONLY have short options and missing long option!
	foreach ( sort keys (%{$l2s}) ) {
	  my $longopt = "$_";
	  my $shortopt = $l2s->{"$_"};
	  my $defvalue = $default_vals->{"$_"};
	  
	  if ( $is_debug ) {
	    my @outputstr;
	    if ( defined($longopt) ) {
	      push(@outputstr, "L : <$longopt>");
	    }
	    if ( defined($shortopt) ) {
	      push(@outputstr, "S : <$shortopt>");
	    }
	    if ( defined($defvalue) ) {
	      push(@outputstr, "Def value : <$defvalue>");
	    }
	    if ( defined($longopt) && defined($argsref->{"$longopt"}) ) {
	      push(@outputstr, "Current value (L) : <$argsref->{$longopt}>");
	    } else {
	      if ( defined($shortopt) && defined($argsref->{"$shortopt"}) ) {
	        push(@outputstr, "Current value (S) : <$argsref->{$shortopt}>");
	      }
	    }
	
	    &__print_debug_output(join(' || ',@outputstr));
	  }
	
	  if ( defined($shortopt) && defined($argsref->{"$shortopt"}) ) {
	    &__print_debug_output("Transfer from short to long") if ( $is_debug );
	    $argsref->{"$longopt"} = $argsref->{"$shortopt"};
	  } else {
	    if ( defined($longopt) && (not defined($argsref->{"$longopt"})) ) {
	      &__print_debug_output("Use default") if ( $is_debug );
	      $argsref->{"$longopt"} = $defvalue if ( defined($defvalue) );
	    } else {
	      &__print_debug_output("Keep value stored in long") if ( $is_debug );
        }
	  }
	}
	
	return;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;