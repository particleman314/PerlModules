package HP::Capsule::UseCaseCapsule;

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
    use lib "$FindBin::Bin/..";

	use parent qw(HP::Capsule::Common);
	
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

    $VERSION = 1.00;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'                           => undef,
							'HP::Support::Base'                       => undef,
							'HP::Support::Base::Constants'            => undef,
							'HP::Support::Hash'                       => undef,
							'HP::Support::Configuration'              => undef,
							'HP::Support::Object'                     => undef,
							'HP::Support::Object::Tools'              => undef,
							'HP::Support::Object::Constants'          => undef,
							'HP::CheckLib'                            => undef,
							'HP::String'                              => undef,
							
							'HP::Array::Tools'                        => undef,
							'HP::Capsule::Tools'                      => undef,
							'HP::CSL::Tools'                          => undef,
							'HP::OOStudio::Constants'                 => undef,
							'HP::CapsuleMetadata::UseCase::Constants' => undef,
							'HP::Capsule::Constants'                  => undef,
							
							'HP::FileManager'                         => undef,
							'HP::Path'                                => undef,
							'HP::Copy'                                => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsule_usecasecapsule_pm'} ||
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
sub add_ooflow
  {
    my $self      = shift;
	my $ooversion = shift;
	my $dep       = shift;
	my $caplist   = shift;
	
	my $type = shift || DELIVERY;
	my $path = shift || NON_HPLN;
	
	return FALSE if ( not defined($ooversion) );
	return FALSE if ( not defined($dep) );
	return FALSE if ( not defined($caplist) || ref($caplist) !~ m/^array/i );
	
	my $derived   = &get_from_configuration('derived_data');
	my $gdi       = &get_global_datastore();

	my $ooflow = &create_object('c__HP::CapsuleMetadata::UseCase::DependencyTypes::ooflow__');
	$ooflow->ooTag($ooversion);

	foreach my $cap ( @{$caplist} ) {
	  my $artifact = $self->prepare_artifact($ooversion, $cap);
	  if ( not defined($artifact) ) {
	    &__print_output("Unable to add artifact for << $cap >> to ooflow node << $ooversion >>", WARN);
		next;
	  }
	  $ooflow->add_artifact($artifact);  
	}
	
	$dep->deptypes()->push_item($ooflow) if ( $ooflow->number_artifacts() > 0 );
	return TRUE;
  }
  
#=============================================================================
sub classify
  {
    my $self   = shift;
	my $ldi    = $self->local_data();
	my $result = 'unknown';
	
	if ( defined($ldi) ) {
	  my $classification = $ldi->get_build_parameter('csl->content->type');
	  return $classification if ( defined($classification) );
	  return $result;
	}
	
	return $result;
  }
  
#=============================================================================
sub collect_service_designs
  {
    my $self = shift;
	
	my $argsref   = &get_from_configuration('program->user_arguments');
	my $derived   = &get_from_configuration('derived_data');
	my $gdi       = &get_global_datastore();
	my $buildpath = $argsref->{'build-path'};

	my $usecase   = $self->usecase() || $self->workflow();  # Use workflow if shared ooflows
	return FALSE if ( not defined($usecase) );
	
	my $product_dir = &join_path("$buildpath", $gdi->get_build_parameter('package->productdir'));
	&make_recursive_dirs("$product_dir") if ( &does_directory_exist("$product_dir") eq FALSE );

	my $provider_matrix = $gdi->{'providerMapping'};
	my $ucprod = &join_path("$product_dir", "$usecase");

	my ( $capsule, $provider, $localdata ) = &get_all_capsule_components("$usecase");
	
	my $capsule_manager = &get_capsule_data();
	my $sd_container    = shift;
	
	my $ucversion    = &generate_version($provider, $capsule, $localdata);
    my $uc_sd_path   = &join_path("$buildpath", "$usecase", CSA_DESIGN_DIR);
	my $organization = &collect_directory_contents("$uc_sd_path");
	
	my $mentioned_sds = $localdata->collect_all_service_design_names();
	if ( scalar(@{$organization->{'files'}}) != scalar(@{$mentioned_sds}) ) {
	  &__print_output('Recorded '. scalar(@{$mentioned_sds}) .' but found '. scalar(@{$organization->{'files'}}) . " service designs for << $usecase >>", WARN);
	}
	
	my $possible_dispname = undef;
	$possible_dispname = $capsule->get_parameters()->{'displayname'} if ( defined($capsule) );	# From capsule directive file
	
	foreach ( @{$organization->{'files'}} ) {
	  next if ( &is_zip_file("$_") eq FALSE );
	  
	  my $sd = &remove_extension("$_");
	  if ( &set_contains("$sd", $mentioned_sds) eq FALSE ) {
	    &__print_output("Found service design < $_ >, but it was NOT registered in local data XML file for $usecase", WARN);
		&__print_output("Removing service design < $_ >", WARN);
		&delete(&join_path("$uc_sd_path", "$_"));
		next;
	  }
	  
	  my $sdentry = $localdata->get_service_design_entry("$sd");
	  my @capsule_ids = $sdentry->get_dependency_capsules();
	  
	  #my @capsule_ids = $capsule_manager->get_all_subcapsules();
	  my $sdobj = &clone_item(&get_template_obj($sd_container->blueprint()));
	  
	  $sdobj->name("$sd");
	  $sdobj->version()->set_version(&generate_sd_version("$sd", $localdata));
	  $sdobj->description(&generate_sd_description("$sd", $localdata));
	  
	  my $matching_capsule_id = $self->find_matching_capsule("$sd", \@capsule_ids);
	  my $specific_dispname   = $sdentry->displayName();
		
	  if ( defined($matching_capsule_id) ) {
	    my $provider = &get_matching_provider("$matching_capsule_id");
		if ( defined($provider) ) {
		  $matching_capsule_id    = $gdi->get_normalized_provider_name($provider->usecase());
		  my $reduced_capsule_set = $provider_matrix->get_reduced_group(\@capsule_ids, $provider->name());
		  @capsule_ids = @{$reduced_capsule_set};
		}
		
		$sdobj->displayName( &choose_proper_specificity($possible_dispname,
		                                                $specific_dispname,
													    "$matching_capsule_id Service Design") )
	  } else {
		$sdobj->displayName( &choose_proper_specificity($possible_dispname,
		                                                $specific_dispname,
													    "$usecase service design") )
	  }
	  
	  # Build dependencies...
	  foreach my $oov ( @{$argsref->{'hpoo'}} ) {
	    my $dependency = &clone_item(&get_template_obj($sdobj->dependencies()));
		
		my @combined_list  = ();
		push ( @combined_list, @capsule_ids );
		
		$self->add_ooflow($oov, $dependency, \@combined_list);		
		$sdobj->dependencies()->push_item($dependency) if ( $dependency->number_dependencies() > 0 );
	  }
	  $sd_container->blueprint()->push_item($sdobj);
	}
	return TRUE;
  }

#=============================================================================
sub data_types
  {
    my $self        = shift;
	my $which_level = shift || COMBINED;
	
    my $data_fields = {
		              };
					  
    if ( $which_level eq COMBINED ) {
      foreach ( @ISA ) {
	    my $parent_types = undef;
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
    return $data_fields;
  }

#=============================================================================
sub find_matching_capsule
  {
    my $result  = undef;
	my $self    = shift;
    my $sdname  = shift || return $result;
	my $capids  = shift;
		
	foreach ( @{$capids} ) {
	  my $provider = &get_matching_provider("$_");
      if ( defined($provider) ) {
	    my $sd_pattern = $provider->sd_pattern();
		if ( defined($sd_pattern) ) {
		  if ( $sdname =~ m/^SERVICE.*($sd_pattern).*\.zip$/ ) {
		    $result = $_;
			last;
		  }
		}
	  }
	}
	
	return $result;
  }
  
#=============================================================================
sub generate_installer_data
  {
    my $self = shift;
	my $capsule = shift || return;
  }

#=============================================================================
sub generate_usecase_zip
  {
    my $self      = shift;
	my $usecase   = $self->usecase() || $self->workflow() || return FAIL;

	# Get definition data from configuration area
	my $derived   = &get_from_configuration('derived_data');
	my $buildpath = &get_from_configuration('program->user_arguments->build-path');
	my $gdi       = &get_global_datastore();
    my $ccc       = $derived->{'cloudcapsule'};
	
	# Setup product directory (if not already setup)
	my $product_dir = &join_path("$buildpath", $gdi->get_build_parameter('package->productdir'));
	&make_recursive_dirs("$product_dir") if ( &does_directory_exist("$product_dir") eq FALSE );

	# Prepare usage by accessing common components
	my $ucdir     = $self->usecase_dir();

	my $capsule_manager = &get_capsule_data();
	my $capsule         = $capsule_manager->find_usecase_capsule("$usecase");	
	my $error_status    = PASS;
	
	if ( &does_directory_exist("$ucdir") eq FALSE ) {
	  &__print_output("Unable to find usecase directory << $ucdir >>", FAILURE);
	  return FAIL;
	}
	
	my $ucprod   = &join_path("$product_dir", "$usecase");
	my $uccomps  = $gdi->get_build_parameter('package->single_install->copy_content');
	
	# Copy over necessary sub components
	foreach my $uccomp ( @{$uccomps->{'dirs'}->{'name'}} ) {  # Need enhancement to handle files and directories TODO
	  &__print_output("Preparing contents for usecase capsule << $usecase >> [ $uccomp ]");
      my $startdir = &path_to_unix(&join_path("$ucdir", "$uccomp"));
	  if ( &does_directory_exist("$startdir") eq TRUE ) {
	    $error_status = &copy_with_rsync("$startdir", "$ucprod" );
		
		if ( $error_status ne TRUE ) {
		  &__print_output("Unable to properly copy << $uccomp >> for use case << $usecase >>!", WARN);
		}
	  }
	}
	
	my $provider = &get_matching_provider("$usecase");
	return FAIL if ( ref($provider) =~ m/^array/i );
	
	if ( (not defined($capsule)) && defined($provider) ) {
	  $capsule = $capsule_manager->find_oo_capsule($provider->usecase());
	  if ( not defined($capsule) ) {
	    &__print_output("Unable to find use necessary capsule data for << $usecase >>");
		return FAIL;
	  }
	  $capsule->name($provider->name());
	}

	# Begin preparation of the metadata for usecase
	my $localdata  = &get_local_data_for_usecase($provider->usecase());

	my $capversion = &generate_version($provider, $capsule, $localdata);

	my $uc_metadata = &create_object('c__HP::CapsuleMetadata::UseCase__');
	if ( not defined($uc_metadata) ) {
	  &__print_output("Unable to generate usecase metadata structure", FAILURE);
	  return FAIL;
	}
	
	$uc_metadata->publisher(&generate_publisher($provider, $capsule, $localdata));
	
	my $translated_name = &generate_sd_capsule_name($provider, $capsule, $localdata);
	#$translated_name = "$translated_name";
	#$translated_name =~ s/[\.|\s]/_/g;  # Remove spaces and periods
	
	my $installdata = $uc_metadata->installerData();
	$installdata->name("$translated_name");
	$installdata->description(&generate_description($provider, $capsule, $localdata));
	
	# TODO -- Add the scripts selected to be pushed to the installdata section
	#$self->collect_scripts($installdata->scripts());	
	
	# Should use the same means to generate the version for the oo package
	my $vobj = &create_object('c__HP::VersionObject__');
	$vobj->set_version($gdi->get_build_parameter('package->release_id'));
	$installdata->version($vobj);
	$uc_metadata->installerData($installdata);
	
	# Collect all the service designs listed (warn if the number don't match and remove those which don't)
	$self->collect_service_designs($installdata->serviceblueprints());
	
	my $merged_matrix = $self->merge_support_matrices($gdi->{'supportMatrix'}, $localdata->{'supportMatrix'});
	$uc_metadata->supportMatrix($merged_matrix) if ( defined($merged_matrix) );
	$uc_metadata->write_xml(&join_path("$ucprod", 'usecase_capsule.manifest'));
	
	$localdata->add_metadata($uc_metadata, 'usecase');
	
	# Build the zipfile for the contents.
	my $finalized_name = "$translated_name.zip";
	my $zipobj = &create_object('c__HP::Zip::SevenZip__');
	$zipobj->add_contents("$ucprod");
	
	my $zipname = &join_path("$product_dir", "$finalized_name");
	$zipobj->store_location("$zipname");
	$error_status = $zipobj->store();
	&delete("$ucprod");

	if ( $error_status ne PASS ) {
	  &__print_output("Unable to make zipfile for $finalized_name", FAILURE);
	  return $error_status;
	}
	
	# Store away the metadata for this capsule and items produced
	if ( defined($localdata) ) {
	  $localdata->add_parameter('produced_usecase', $finalized_name);
	}

	my $tagid = $provider->usecase();
		
	$gdi->{'produced_items'} = {} if ( not defined($gdi->{'produced_items'}) );
	$gdi->{'produced_items'}->{$tagid} = &create_object('c__HP::Array::Set__') if ( not defined($gdi->{'produced_items'}->{$tagid}) );
	$gdi->{'produced_items'}->{$tagid}->push_item("$zipname");

	return PASS;
  }
  
#=============================================================================
sub get_type
  {
    my $self = shift;
	return 'usecase';
  }

#=============================================================================
sub load_local_xmldata
  {
    my $self = shift;
	my $buildpath = shift;
	
	my $path = $self->SUPER::load_local_xmldata("$buildpath", 'name');
	$self->usecase_dir("$path") if ( defined($path) );
	return;
  }
  
#=============================================================================
sub merge_support_matrices
  {
    my $self = shift;
	my $sm1  = shift;
	my $sm2  = shift;
	
	return undef if ( (not defined($sm1)) && (not defined($sm2)) );
	return $sm1->clone()  if ( not defined($sm2) );
	return $sm2->clone()  if ( not defined($sm1) );
	
	my $merged_sm = $sm1->clone();  # Need to work on a cloned version
	$merged_sm->add_support_matrix($sm2);
	
	return $merged_sm;
  }
  
#=============================================================================
sub new
  {
    my $class       = shift;
    my $data_fields = &data_types();

    my $self = {
		        %{$data_fields},
	           };
			   
	if ( @_ ) {
	  if ( ref($_[0]) =~ m/hash/i ) {
	    foreach my $key (keys{%{$_[0]}}) {
		  if ( exists($self->{"$key"}) ) {
		    $self->{"$key"} = $_[0]->{"$key"};
		  }
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class << $class >>", 'STDERR');
		return undef;
	  }
	}
	
    bless $self, $class;
	$self->instantiate();
	return $self;  
  }

#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	
	$self->version()->set_version(${$self->get_parameters()->{'version'}});
	delete($self->get_parameters()->{'version'});
		
	my $gds = &get_global_datastore();
	if ( defined($gds) ) {
	  my $provider = $gds->get_matching_provider($self->name());
	  if ( &is_type($provider, 'HP::ArrayObject') eq TRUE ) {
	    &__print_output("Unable to discern proper OO capsule name due to ambiguity!", FAILURE);
		return FALSE;
	  }
	  
	  if ( defined($provider) ) {
	    $self->name($provider->name());
	    $self->usecase($provider->usecase());
	  } else {
	    return FALSE;
	  }
	}

	return TRUE;
  }
  
#=============================================================================
sub prepare_artifact
  {
    my $self      = shift;
	my $ooversion = shift;
	my $capID     = shift;

	my $type = shift || DELIVERY;
	my $path = shift || NON_HPLN;
	
	return undef if ( not defined($ooversion) );
	return undef if ( not defined($capID) );
	
	my $derived   = &get_from_configuration('derived_data');
	my $gdi       = $derived->{'global'};

	my $artifact = &create_object('c__HP::CapsuleMetadata::UseCase::Artifact__');
	$artifact->type($type);
	$artifact->path($path);
		  
	if ( &str_starts_with($ooversion, [ OO_VERSION_10 ]) eq TRUE ) {
	  my $provider = undef;
	  if ( &str_starts_with($capID, [ 'com.hp.csl' ]) eq FALSE ) {
        $provider = &get_matching_provider("$capID");
	    if ( not defined($provider) ) {
		  &__print_output("Unable to find information in provider matrix for << $capID >>", WARN );
		  return undef;
	    }
	    $artifact->value($provider->value());
      } else {
	    $artifact->value($capID);
	  }  
		
	  my $vobj = &create_object('c__HP::VersionObject__');
	  $vobj->set_version($gdi->get_build_parameter(&uppercase_all($ooversion).'->oo->content->cpversion'));
	  $artifact->version($vobj);
	} else {
	  $artifact->value($gdi->get_build_parameter(&uppercase_all($ooversion).'->oo->content->single_installer_file'));
	}
	  
	return $artifact;
  }

#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
1;