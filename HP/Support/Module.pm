package HP::Support::Module;

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
    use lib "$FindBin::Bin/../..";

    use vars qw(
				$VERSION
				$is_debug
				$is_init

				$module_require_list
                $module_request_list

				$broken_install

                $module_callback
		
				@ISA
				@EXPORT
               );

    $VERSION    = 1.00;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
				 &convert_from_colon_module
				 &convert_to_colon_module
                 &find_pm_location
                 &get_full_qualified_module_name
                 &has
                 &install_os_dependent_modules
				 &module_routine
				 &show_inc_hash
				 &show_inc_path
                );

    $module_require_list = {
							'File::Basename'                 => undef,
							
							'HP::Constants'                  => undef,
							'HP::Support::Base'              => undef,
							'HP::Support::Os'                => undef,
							'HP::Support::Module::Constants' => undef,
							'HP::Support::Module::Tools'     => undef,
							'HP::Support::Object::Tools'     => undef,
							
							'HP::CheckLib'                   => undef,
						   };
    $module_request_list = {
	                       };

    $module_callback     = {};

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_support_module_pm'} ||
			$ENV{'debug_support_modules'} ||
			$ENV{'debug_hp_modules'} ||
			$ENV{'debug_all_modules'} || 0
		);

    $broken_install = 0;

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
	    if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
          eval "use $usemod;";
        }
	    if ( $@ ) {
	      print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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

#=============================================================================
sub __initialize()
  {
    if ( $is_init eq $local_false) {
      $is_init = $local_true;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
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
sub __os_depend_install($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $mods = $_[0];

    &__print_debug_output("Hash/Map list -->".Dumper($mods), __PACKAGE__) if ( $is_debug );
    
    if ( ( ref($mods) =~ m/hash/i ) && ( defined($mods) ) ) {
      foreach my $mod (keys(%{$mods})) {
	    &__print_debug_output("Checking for pre-installation OS module --> $mod\n", __PACKAGE__) if ( $is_debug );
	
	    my $data   = $mods->{"$mod"};
	    my $answer = &has("$mod");

	    if ( $answer eq FALSE ) {
	      &__print_debug_output("Attempting installation of [ $mod ]\n", __PACKAGE__) if ( $is_debug );
		  my ( $result, $errmsg ) = &require_packages([ $mod ]);
		  if ( $result->[0] eq TRUE ) {
	        &__print_debug_output("Loaded module [ $mod ]\n", __PACKAGE__) if ( $is_debug );
	      }
	      &__print_debug_output("Attachment in progress...\n", __PACKAGE__ ) if ( $is_debug );
	    }

	    &__print_debug_output("Module Callback Hash --> ".Dumper($module_callback), __PACKAGE__) if ( $is_debug );
	    if ( ref($data) =~ m/hash/i ) {
	      &__print_debug_output("Checking [ $mod ] in callback hash...\n",__PACKAGE__) if ( $is_debug );
	    REGISTER:
	      # Register call back for this module...
	      if ( exists($HP::Support::Module::module_callback->{"$data->{'alias'}"}) ) {
	        my $thismod = $HP::Support::Module::module_callback->{"$data->{'alias'}"};
	        $thismod->{"$data->{'subroutine'}"} = "$mod";
	      } else {
	        $HP::Support::Module::module_callback->{"$data->{'alias'}"} = {};
	        goto REGISTER;
	      }
	    }
      }
    }
    
    &__print_debug_output("Module Callback Hash --> ".Dumper($module_callback), __PACKAGE__) if ( $is_debug );
	return;
  }

#=============================================================================
sub convert_from_colon_module(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my @result = ();
	
    my $colon_regex   = &convert_to_regexs(&COLON_OPERATOR);
    my $perlext_regex = &convert_to_regexs(&PERLMOD_EXTENSION);

    foreach (@_) {
      my $module = $_;

      # Convert "::" to "/" and then check for additional
      # hash information as part of a quoted word call.
      # Insert the trailing ".pm" as necessary

      $module =~ s/$colon_regex/\//g;
      $module =~ s/$perlext_regex//g;
      $module = $module.&PERLMOD_EXTENSION;

      &__print_debug_output("$_ is converted to $module", __PACKAGE__);
      push( @result, $module );
    }

	# Manage return types here
	my $requested_answer = wantarray();

	if ( $requested_answer ) { return @result };
	if ( (not defined($requested_answer)) || ($requested_answer eq '') ) {
	  return \@result;
	}
  }

#=============================================================================
sub convert_to_colon_module(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @result = ();

    my $colon_regex   = &convert_to_regexs(&COLON_OPERATOR);
    my $perlext_regex = &convert_to_regexs(&PERLMOD_EXTENSION);

    foreach (@_) {
      my $module = $_;

      # Convert "/" to "::" and then check for additional
      # hash information as part of a quoted word call.
      # Remove the trailing ".pm"

      $module =~ s/\//$colon_regex/g;
      $module =~ s/$perlext_regex//g;
      $module =~ s/\\//g;
      &__print_debug_output("$_ is converted to $module", __PACKAGE__);
      push( @result, $module );
    }

	# Manage return types here
	my $requested_answer = wantarray();

	if ( $requested_answer ) { return @result };
	if ( (not defined($requested_answer)) || ($requested_answer eq '') ) {
	  return \@result;
	}
  }

#=============================================================================
sub find_pm_location($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return [] if ( scalar(@_) < 1 );

    my @modules = &convert_from_colon_module(@_);
    &__print_debug_output("Modules to search -->".Dumper(\@modules), __PACKAGE__) if ( $is_debug );

    my @result = ();
	$result[scalar(@modules) - 1] = undef;
	
    for ( my $loop = 0; $loop < scalar(@modules); ++$loop ) {
	  $result[$loop] = $INC{"$modules[$loop]"}
    }
	
    &__print_debug_output("Locations found to match -->".Dumper(\@result), __PACKAGE__) if ( $is_debug );

	return $result[0] if ( scalar(@_) == 1 );
    return \@result;
  }

#=============================================================================
sub get_full_qualified_module_name($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $result = undef;
    my $module_location = $_[0];

    goto __END_OF_SUB if ( not defined($module_location) );
    goto __END_OF_SUB if ( length($module_location) < 1 );

	$result = [];
	
    my $regex = &convert_to_regexs(&PERLMOD_EXTENSION);
    if ( $module_location !~ m/$regex$/ ) { $module_location .= PERLMOD_EXTENSION; }

    if ( -f "$module_location" ) {
      my $data = undef;

	  # Low-level open
      if ( open( MODULE, "<", "$module_location" ) ) {
	    $data = <MODULE>;  # Grab first line in file...
	    close(MODULE);
      } else {
	    $result = "$module_location";
		goto __END_OF_SUB;
      }

      if ( $data =~ m/package\s*(\S*)\s*\;/ ) {
	    $data = $1;
      }
	  $result = $data;
      goto __END_OF_SUB;
    } else {
      $result = "$module_location";
    }
	
  __END_OF_SUB:
	return $result;
  }
 
#=============================================================================
sub has(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @result = ();
    goto FINISH if ( scalar(@_) < 1 );
	
    my @modules = &convert_from_colon_module(@_);
	$result[scalar(@modules) - 1] = undef;
    &__print_debug_output("Modules to search -->".Dumper(\@modules), __PACKAGE__) if ( $is_debug );

    for ( my $loop = 0; $loop < scalar(@modules); ++$loop ) {
      my $existMod = ( exists($INC{"$modules[$loop]"}) ) || FALSE;
      my $definedMod = ( defined($INC{"$modules[$loop]"}) ) || FALSE;
      &__print_debug_output("Exist/Defined module << $modules[$loop] >> -- [ $existMod | $definedMod ]\n", __PACKAGE__);
      $result[$loop] = $existMod && $definedMod;
    }
	
  FINISH:
    &__print_debug_output("Result -->".Dumper(\@result), __PACKAGE__) if ( $is_debug );
	
	return undef if ( scalar(@_) == 0 );
	return $result[0] if ( scalar(@_) == 1 );
    return \@result;
  }

#=============================================================================
sub install_os_dependent_modules($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $lnx_mods = $_[0];
    my $win_mods = $_[1];
    my $cyg_mods = $lnx_mods;

    # Allow cygwin to be handled differently from linux or windows if
    # requested; otherwise use linux version of mods...
    if ( scalar(@_) > 2 ) {
      &__print_debug_output("Using specific Cygwin module support\n", __PACKAGE__);
      $cyg_mods = $_[2];
    }

    if ( ( &os_is_linux() eq TRUE ) && ( defined($lnx_mods) ) && ( ref($lnx_mods) =~ m/hash/i ) ) {
      &__print_debug_output("Handling Linux OS dependent modules\n", __PACKAGE__) if ( $is_debug );
      &__os_depend_install($lnx_mods);
      goto __END_OF_SUB;
    }
    if ( ( &os_is_cygwin() eq TRUE ) && ( defined($cyg_mods) ) && ( ref($cyg_mods) =~ m/hash/i ) ) {
      &__print_debug_output("Handling Cygwin dependent modules\n", __PACKAGE__) if ( $is_debug );;
      &__os_depend_install($cyg_mods);
      goto __END_OF_SUB;
    }
    if ( ( &os_is_windows_native() eq TRUE ) && ( defined($win_mods) ) && ( ref($win_mods) =~ m/hash/i ) ) {
      &__print_debug_output("Handling Native Windows dependent modules\n", __PACKAGE__) if ( $is_debug );;
      &__os_depend_install($win_mods);
      goto __END_OF_SUB;
    }
	
  __END_OF_SUB:
	return;
  }

#=============================================================================
sub module_routine($)
  {
    my $fullpathroutine = $_[0];
	my ( $module, $routine ) = (undef, undef);
	
	goto __END_OF_SUB if ( &valid_string($fullpathroutine) eq FALSE );

    my $converted     = &convert_from_colon_module($fullpathroutine);
    my $perlext_regex = &convert_to_regexs(&PERLMOD_EXTENSION);
	
	$module  = File::Basename::dirname($converted->[0]);
	$routine = File::Basename::basename($converted->[0]);
	
	$module  = &convert_to_colon_module($module);
	$module  = $module->[0];
	$routine =~ s/$perlext_regex//g;
	
	return ($module, $routine);
  }
  
#=============================================================================
sub show_inc_hash()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    foreach (sort keys %INC) {
      &__print_output("$_ --> $INC{$_}", __PACKAGE__);
    }
    print STDERR "\n";
	return;
  }

#=============================================================================
sub show_inc_path()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    &__print_output("\@INC Path = ". join(' ', @INC). "\n", __PACKAGE__);
	return;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;