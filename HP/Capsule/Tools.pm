package HP::Capsule::Tools;

################################################################################
# Copyright (c) 2013-2014 HP.   All rights reserved
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

use strict;
use warnings;
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

				@ISA
                @EXPORT
               );

    $VERSION = 0.75;

	@ISA  = qw(Exporter);	
    @EXPORT  = qw (
	               &choose_proper_specificity
	               &generate_capsule_name
				   &generate_sd_capsule_name
				   &generate_description
				   &generate_sd_description
				   &generate_publisher
				   &generate_version
				   &generate_sd_version
				   &get_all_capsule_components
				   &get_capsule_data
				   &get_local_data_for_usecase
	               &get_matching_provider
                  );

    $module_require_list = {
							'HP::Constants'               => undef,
							'HP::Support::Base'           => undef,
							'HP::Support::Hash'           => undef,
							'HP::Support::Object::Tools'  => undef,
							'HP::Support::Configuration'  => undef,
							
							'HP::CheckLib'                => undef,
							
							'HP::CSL::Tools'              => undef,
							'HP::Capsule::Constants'      => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsule_tools_pm'} ||
                 $ENV{'debug_capsule_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t-->Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod\n" if ( $is_debug ); 
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
sub __find_common_display_content($)
  {
    my $usecase = shift;
	my $key     = shift;
	
	return undef if ( &valid_string($usecase) eq FALSE || &valid_string($key) eq FALSE );
	
	my $capsule_directive = &get_capsule_data();
	if ( defined($capsule_directive) ) {
	  my $capsule_section = $capsule_directive->find_capsule($usecase);
	
	  if ( defined($capsule_section) ) {
	    my $cmndisp = $capsule_section->get_parameters()->{'common_display'};
	    if ( defined($cmndisp) ) {
		  # TODO : Use Configuration support to make this easier and less error prone
	      my $tempdata = $capsule_directive->common_info()->configuration()->{${$cmndisp}}->{'entry'}->{$key} || undef;
		  return ${$tempdata} if ( defined($tempdata) );
	    }
	  }
	}
	return undef;
  }
  
#=============================================================================
sub __generate_userdefine_localdata_content($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([
	                                       'capsule',         \&is_blessed_obj,
										   'localdata',       \&is_blessed_obj,
										   'user_configpath', \&valid_string,
										   'ld_configpath',   \&valid_string,
										  ], @_);
    }
    return if ( scalar(keys(%{$inputdata})) == 0 );

	my $data = undef;
	
    my $capsule  = $inputdata->{'capsule'};
	my $ld       = $inputdata->{'localdata'};
	my $uc_path  = $inputdata->{'user_configpath'};
	my $ld_path  = $inputdata->{'ld_configpath'};
	
	my $capsule_manager = &get_capsule_data();
	my $user_data       = undef;
	
	if ( defined($capsule) ) {
	  my $capman_overrides = $capsule_manager->find_capsule_input_data($capsule->name());
	  
	  if ( defined($capman_overrides->get_parameters()->{"$uc_path"}) ) {
	    my $temp = $capman_overrides->get_parameters()->{"$uc_path"};
	    $user_data = ${$temp} if ( ref($temp) =~ m/scalar/i );
		$user_data = $temp if ( ref($temp) eq '' );
	  }
	  $user_data = ( &valid_string($user_data) eq TRUE ) ? $user_data : undef;
	}
	
	my $temp       = undef;
	my $local_data = undef;
	if ( defined($ld) ) {
	  $temp = $ld->get_build_parameter("$ld_path") if ( defined($ld) );
	  $local_data = ( &valid_string($temp) eq TRUE ) ? $temp : undef;
    }
	
	$data = "$local_data" if ( defined($local_data) );
	$data = "$user_data" if ( defined($user_data) );

	return $data;
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
sub choose_proper_specificity($$$)
  {
    my $general  = shift;
	my $specific = shift;
	my $default  = shift;
	my $result   = $default;
	
	if ( defined($specific) ) {
	  $result = $specific;
	} else {
	  if ( defined($general) ) {
	    $result = $general;
	  }
	}
	return $result;
  }

#=============================================================================
sub generate_sd_capsule_name($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $default_name = 'com.hp.csl.unknown';
	
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([
	                                       'provider',  \&is_blessed_obj,
	                                       'capsule',   \&is_blessed_obj,
										   'localdata', \&is_blessed_obj
										  ], @_);
    }
    return if ( scalar(keys(%{$inputdata})) == 0 );

    my $provider = $inputdata->{'provider'};
    my $capsule  = $inputdata->{'capsule'};
	my $ld       = $inputdata->{'localdata'};

	# Set using generic default...
	my $name = $default_name;

	# Ask if should replace with capsule Identification
    $name = $capsule->value() || $capsule->workflow() || $capsule->name() if ( defined($capsule) );
	
	# Find if localdata file for usecase or user override should supercede
	my $possible_name = &__generate_userdefine_localdata_content($capsule, undef, 'sdname', undef);	
	if ( not defined($possible_name) ) {
	  $possible_name = &__generate_userdefine_localdata_content($capsule, $ld, 'displayname', 'human->name');	
	}

	$name = "$possible_name" if ( &valid_string($possible_name) eq TRUE );

	return $name;
  }

#=============================================================================
sub generate_capsule_name($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $default_name = 'com.hp.csl.unknown';
	
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([
	                                       'provider',  \&is_blessed_obj,
	                                       'capsule',   \&is_blessed_obj,
										   'localdata', \&is_blessed_obj
										  ], @_);
    }
    return if ( scalar(keys(%{$inputdata})) == 0 );

    my $provider = $inputdata->{'provider'};
    my $capsule  = $inputdata->{'capsule'};
	my $ld       = $inputdata->{'localdata'};

	# Set using generic default...
	my $name = $default_name;

	# Ask if should replace with capsule Identification
    $name = $capsule->value() || $capsule->workflow() || $capsule->name() if ( defined($capsule) );
	
	# Find if localdata file for usecase or user override should supercede
	my $possible_name = &__generate_userdefine_localdata_content($capsule, $ld, 'displayname', 'human->name');
	
	my $requested_common_info = &__find_common_display_content($capsule->usecase(), 'displayname');
	$possible_name = $requested_common_info if ( defined($requested_common_info) );
	$name = "$possible_name" if ( &valid_string($possible_name) eq TRUE );

	return $name;
  }

#=============================================================================
sub generate_description($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
 
	my $default_description = 'No Description Available';
	
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([
	                                       'provider',  \&is_blessed_obj,
	                                       'capsule',   \&is_blessed_obj,
										   'localdata', \&is_blessed_obj
										  ], @_);
    }
    return if ( scalar(keys(%{$inputdata})) == 0 );

    my $provider = $inputdata->{'provider'};
    my $capsule  = $inputdata->{'capsule'};
	my $ld       = $inputdata->{'localdata'};

	# Set using generic default...
	my $description = $default_description;

	# Find if localdata file for usecase or user override should supercede
	my $possible_description = &__generate_userdefine_localdata_content($capsule, $ld, 'description', 'oo->flow->repo->description');

	my $requested_common_info = &__find_common_display_content($capsule->usecase(), 'description');
	$possible_description = $requested_common_info if ( defined($requested_common_info) );
	$description = "$possible_description" if ( &valid_string($possible_description) eq TRUE );

	return $description;
  }

#=============================================================================
sub generate_sd_description($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
 
	my $default_description = 'No Description Available for Service Design';
	
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([
	                                       'sdname',    \&valid_string,
										   'localdata', \&is_blessed_obj
										  ], @_);
    }
    return if ( scalar(keys(%{$inputdata})) == 0 );

	my $sdname   = $inputdata->{'sdname'};
	my $ld       = $inputdata->{'localdata'};

	# Set using generic default...
	my $description = $default_description;

	my $sdobj = $ld->get_service_design_entry("$sdname");
	$description = $sdobj->description() if ( defined($sdobj) );
	return $description;  
  }

#=============================================================================
sub generate_sd_version($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
 
    my $nullversion = NULLVERSION;
	
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([
	                                       'sdname',    \&valid_string,
										   'localdata', \&is_blessed_obj
										  ], @_);
    }
    return if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $sdname   = $inputdata->{'sdname'};
	my $ld       = $inputdata->{'localdata'};
	
	# Set using generic default...
	my $version = $nullversion;

	my $sdobj = $ld->get_service_design_entry("$sdname");
	$version = $sdobj->version()->get_version() if ( defined($sdobj) );
	return $version;
  }

#=============================================================================
sub generate_publisher($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $default_publisher = 'CSA';
	
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([
	                                       'provider',  \&is_blessed_obj,
	                                       'capsule',   \&is_blessed_obj,
										   'localdata', \&is_blessed_obj
										  ], @_);
    }
    return if ( scalar(keys(%{$inputdata})) == 0 );
	
    my $provider = $inputdata->{'provider'};
    my $capsule  = $inputdata->{'capsule'};
	my $ld       = $inputdata->{'localdata'};
	
	# Set using generic default...
	my $publisher = $default_publisher;
	
	# Find if localdata file for usecase or user override should supercede
	my $possible_publisher = &__generate_userdefine_localdata_content($capsule, $ld, 'publisher', 'csl->name');

	my $requested_common_info = &__find_common_display_content($capsule->usecase(), 'publisher');
	$possible_publisher = $requested_common_info if ( defined($requested_common_info) );
	$publisher = "$possible_publisher" if ( &valid_string($possible_publisher) eq TRUE );

    return $publisher;
  }

#=============================================================================
sub generate_version($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $nullversion = NULLVERSION;
	
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([
	                                       'provider',  \&is_blessed_obj,
	                                       'capsule',   \&is_blessed_obj,
										   'localdata', \&is_blessed_obj
										  ], @_);
    }
    return $nullversion if ( scalar(keys(%{$inputdata})) == 0 );
	
    my $provider = $inputdata->{'provider'};
    my $capsule  = $inputdata->{'capsule'};
	my $ld       = $inputdata->{'localdata'};
	
	# Set using generic default...
	my $version = $nullversion;

	# Find if localdata file for usecase or user override should supercede
	my $possible_version = &__generate_userdefine_localdata_content($capsule, $ld, 'version', 'csl->content->version');

	if ( defined($capsule) ) {
	  my $requested_common_info = &__find_common_display_content($capsule->usecase(), 'version');
	  $possible_version = $requested_common_info if ( defined($requested_common_info) );
	}
	$version = "$possible_version" if ( &valid_string($possible_version) eq TRUE );
	
	return $version;
  }

#=============================================================================
sub get_all_capsule_components($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $matching_id = shift || return (undef, undef, undef);
	my $key         = shift;
	
	my $capsule_manager = &get_capsule_data();
	
	my $capsule   = $capsule_manager->find_capsule("$matching_id", $key);
	my $provider  = &get_matching_provider("$matching_id");
	my $localdata = undef;
	
	if ( (not defined($capsule)) && defined($provider) ) {
	  $capsule = $capsule_manager->find_usecase_capsule($provider->usecase(), $key);
	}
	$localdata = &get_local_data_for_usecase($capsule->usecase()) if ( defined($capsule) );

	return ( $capsule, $provider, $localdata );
  }
  
#=============================================================================
sub get_capsule_data()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $lds = &get_local_datastore();
	return undef if ( not defined($lds) );
	
	return $lds->{'capsule_xml_directive'};
  }
  
#=============================================================================
sub get_local_data_for_usecase($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $local_data = undef;
	my $capsule_manager = &get_capsule_data();
	return $local_data if ( not defined($capsule_manager) );

    my $matching_id = shift || return undef;	
	return $local_data if ( &valid_string($matching_id) eq FALSE );
	
  	my $gds         = &get_global_datastore();
	return $local_data if ( not defined($gds) );
	
	my $capsule = $gds->get_matching_provider("$matching_id");
	return $local_data if ( ( not defined($capsule) ) || $capsule =~ m/^array/i );
	
	my $identification = $capsule->name();
	
	foreach ( @{$capsule_manager->oo()->get_elements()}, @{$capsule_manager->usecase()->get_elements()} ) {
	  $local_data = $_->local_data() if ( $identification eq $_->name() );
	  next if ( not defined($local_data) );
	  
	  return ${$local_data} if ( ref($local_data) =~ m/^ref/i );
	  return $local_data;
	}

	return $local_data;
  }
  
#=============================================================================
sub get_matching_provider($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $matching_id = shift || return undef;	
  	my $gds         = &get_global_datastore();
	
	return undef if ( not defined($gds) );
	return undef if ( &valid_string($matching_id) eq FALSE );
	
	return $gds->get_matching_provider("$matching_id");
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;