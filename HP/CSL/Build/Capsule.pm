package HP::CSL::Build::Capsule;

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
    use lib "$FindBin::Bin/../../../..";
                            
    use vars qw(           
                $VERSION
                $is_debug
                $is_init 

                $module_require_list
                $module_request_list

                $broken_install
				
                @ISA
                @EXPORT
				
				$shared_flow_map_obj
               );
    
    $VERSION = 0.99;
 
    @ISA    = qw(Exporter);
    @EXPORT = qw(
	             &run_capsule
               );

    $module_require_list = {
	                        'File::Find'                     => undef,
							
                            'HP::Constants'                  => undef,
                            'HP::Support::Base'              => undef,
							'HP::Support::Base::Constants'   => undef,
							'HP::Support::Hash'              => undef,
							'HP::Support::Configuration'     => undef,
							'HP::Support::Screen'            => undef,
							'HP::Support::ProgramManagement' => undef,
							'HP::Support::Module::Tools'     => undef,
							'HP::Support::Object'            => undef,
							'HP::Support::Object::Tools'     => undef,
							'HP::Support::Os'                => undef,
							'HP::Array::Tools'               => undef,
							
							'HP::DBContainer'                => undef,
							'HP::Os'                         => undef,
							'HP::String'                     => undef,
							'HP::Timestamp'                  => undef,
							'HP::FileManager'                => undef,
							'HP::Path'                       => undef,
							'HP::Utilities'                  => undef,
							
							'HP::StreamDB::Constants'        => undef,
							'HP::StreamDB::Tools'            => undef,
							'HP::OOStudio::Constants'        => undef,
							'HP::Capsule::Tools'             => undef,
							'HP::CSL::Constants'             => undef,
							'HP::CSL::Tools'                 => undef,
							'HP::CSL::Build'                 => undef,
                           };

    $module_request_list = {};

    $is_init     = 0;
    $is_debug    = (
		            $ENV{'debug_csl_build_capsule_pm'} ||
		            $ENV{'debug_csl_build_modules'} ||
		            $ENV{'debug_csl_modules'} ||
		            $ENV{'debug_hp_modules'} ||
		            $ENV{'debug_all_modules'} || 0
		           );

    $broken_install      = 0;
	$shared_flow_map_obj = undef;
	
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
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = 1;
	  $shared_flow_map_obj = &create_object('c__HP::Capsule::SharedFlowMap__');
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }       
  }       
 
#=============================================================================
sub build_bom($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $hpoo_version = shift || return FAIL;
	
	my $derived     = &get_from_configuration('derived_data');
	my $argsref     = &get_from_configuration('program->user_arguments');
	my $gds         = &get_global_datastore();
	my $buildpath   = $argsref->{'build-path'};

	my $cc_metadata = &create_object('c__HP::CapsuleMetadata::CloudCapsule__');
	return FAIL if ( not defined($cc_metadata) );
	
	my $buildinfo = $cc_metadata->buildinfo();
	
	my $revision  = &query_jenkins('revision');
	my $buildno   = &query_jenkins('buildid');
	my $builddate = &query_jenkins('builddate');
	
	$buildinfo->svnrevision($revision);
	$buildinfo->buildnumber($buildno);
	$buildinfo->builddate($builddate);
	
	my $capsule_manager = &get_capsule_data();
	my $provider_matrix = $gds->{'providerMapping'};

	my $bom = $cc_metadata->bom();
	my $product_dir = &join_path("$buildpath", $gds->get_build_parameter('package->productdir'));
	my $dircontents = &collect_directory_contents("$product_dir");
	
	my $lds = &get_local_datastore();
	
	foreach ( @{$dircontents->{'files'}} ) {
	  &__print_output("Building BOM entry for $_", INFO);
	  
	  my $bomfile = &get_template_obj($bom->file())->clone();
	  $bomfile->name("$_");
	  $bomfile->md5sum(&get_md5("$_"));
	  
	  if ( defined($capsule_manager) ) {
	    # Select only those files generated from this process
	    foreach my $associated_uc ( sort keys(%{$gds->{'produced_items'}}) ) {
          if ( &set_contains(&join_path("$product_dir","$_"), $gds->{'produced_items'}->{"$associated_uc"}) eq TRUE ) {
		    my ( $capsule, $provider, $localdata ) = &get_all_capsule_components("$associated_uc", 'usecase');
	        my $vID = DEFAULT_VERSION_NUMBER;
	  
  		    my $associated_fn = File::Basename::basename("$_");
			my $gv = &generate_version($provider, $capsule, $localdata);
			$vID = $gv if ( defined($gv) );
  		    my $should_suppress = &convert_string_to_boolean(&get_from_configuration({
			                                                                          'section'     => 'suppress',
																				      'dereference' => TRUE,
																					  'basis'       => $capsule->get_parameters()})) || FALSE;
		    $bomfile->add_data('suppress', 'true', FALSE) if ( $should_suppress eq TRUE );
			
		    my $vobj = &create_object('c__HP::VersionObject__');
	        $vobj->set_version($vID);
	  
	        $bomfile->version($vobj);
	        $bomfile->tag($argsref->{'releaseID'});
	  
	        $bom->add_entry($bomfile);
		  }
	    }
	  }
	}
	
	# Add the OOTB/Tier level content from the usecase capsule
	my $usecases = shift;
	
	my $merged_matrix = $gds->{'supportMatrix'};
	
	if ( defined($usecases) && ref($usecases) =~ m/^array/i ) {
	  my $ootb_set  = &create_object('c__HP::Array::Set__');
      my $global_tiers = $gds->get_tier_table();
	  
	  foreach ( @{$usecases} ) {
		my $provider = $gds->get_matching_provider("$_");
		if ( defined($provider) ) {
		  my $te = $global_tiers->get_tier_entry($provider->value());
		  $cc_metadata->tiertable()->add_entry($te) if ( defined($te) );
		}
		
		# Collect localized necessities
	    my $localdata = &get_local_data_for_usecase("$_");
		if ( not defined($localdata) ) {
		  &__print_output("Unable to find LocalData for provider << $_ >>", WARN);
		  next;
		}
		
		my $OOTBdata = $localdata->collect_all_OOTB_artifacts($hpoo_version);
		$ootb_set->add_elements({'entries' => $OOTBdata});

		# Support of other party software here
        #$merged_matrix = $cc_metadata->merge_support_matrices($merged_matrix, $localdata->{'supportMatrix'});
	  }
	  
	  # Collect all global necessities
	  my $global_OOTBdata = $gds->collect_global_OOTB_artifacts($hpoo_version);
      $ootb_set->add_elements({'entries' => $global_OOTBdata});

	  my $final_elements = $ootb_set->get_elements();
	  $cc_metadata->ootb()->add_elements({'entries' => $final_elements}) if ( $ootb_set->number_elements() > 0 );
	}
	
	# Finally, supply the support matrix...
 	$cc_metadata->supportMatrix($merged_matrix) if ( defined($merged_matrix) );
	$cc_metadata->write_xml(&join_path("$product_dir", 'capsule_pack.manifest'));
	return PASS;
  }
  
#=============================================================================
sub collect_capsule_contents()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $hpoo_version = shift || return 1;

	my $derived      = &get_from_configuration('derived_data');
	my $gds          = &get_global_datastore();
	my $buildpath    = &get_from_configuration('program->user_arguments->build-path');

	my $subcapsules = &get_capsule_data()->get_oo_capsule_ids();
	my $wfc         = &create_object('c__HP::OOStudio::WorkflowCollection__');
	
	my $number_errors  = 0;	
	
	# Use constant hash to allow lookup...
	my $searchfunction = ( $hpoo_version eq OO_VERSION_10 )
	                     ? \&HP::CSL::Build::__locate_OO10_project_file_dir
						 : \&HP::CSL::Build::__locate_OO9_project_file_dir;
	
	# Add code to handle shared OOFlows but still retain individual collection of service design info
	foreach my $sel ( @{$subcapsules} ) {
	  my $capsule = $gds->get_matching_provider("$sel");
	  next if ( ref($capsule) =~ m/^array/i );
	  my $usecase = $capsule->usecase() || $capsule->name();

	  my $shared_flow_path = $capsule->workflow();
	  if ( defined($shared_flow_path) ) {
	    $shared_flow_map_obj->update_map("$shared_flow_path", "$usecase");
	  }
	}
	
	$shared_flow_map_obj->prepare_usage();
	&__print_output("Completed interrogating capsule definitions for \"duplication\"", INFO);
	
	foreach my $sel ( @{$subcapsules} ) {
	  my $capsule = $gds->get_matching_provider("$sel");

	  if ( ref($capsule) =~ m/^array/i ) {
	    &__print_output("Did not find expected number of providers matching --> $sel.  Skipping it...", FAILURE);
		++$number_errors;
		next;
	  }
	  
	  my $usecase = $capsule->usecase() || $capsule->name();
	  my ($wrkflw, $prop_uc) = $shared_flow_map_obj->find_associated_usecase_wrkflw_pair("$usecase");
	  
	  if ( defined($wrkflw) && $usecase ne $prop_uc ) {
	    &__print_output("No need to produce content jarfile for $usecase since its common flow have already slated to be built!", INFO);
	    next;
	  }
	
	  &__print_output("Collecting capsule contents for << $sel >>", INFO);	  
	  my $localdata = &get_local_data_for_usecase("$usecase");
	  
	  if ( not defined($localdata) ) {
	    &__print_output("Unable to find local data storage for << $sel >>", FAILURE);
		++$number_errors;
		next;
	  }
	  
	  my $expected_ooflowdir = $localdata->get_build_parameter("oo->flow->repo->$hpoo_version->directory");
	  if ( not defined($expected_ooflowdir) ) {
	    &__print_output("Unable to find toplevel ooflow data directory for << $sel >>", FAILURE);
		++$number_errors;
		next;	    
	  }
	  
	  my $shared_flow_path = $capsule->workflow();
	  my $repopath = $shared_flow_path || $usecase;  # Allow for shared directory content
      my $startdir = &join_path("$buildpath", "$repopath", "$expected_ooflowdir");
	  &__print_output("Start directory to find flows : $startdir", INFO);
	  
      if ( &does_directory_exist("$startdir") eq TRUE ) {
		
		&find({wanted => $searchfunction, no_chdir => 1}, &path_to_unix("$startdir"));
		
		my $oo_toplevel = $derived->{'oo_toplevel'};
		
		if ( defined($oo_toplevel) ) {
		  $oo_toplevel = ${$oo_toplevel};
		  &__print_output("Found location for OO : $oo_toplevel", INFO);
	      my $wfb = &create_object('c__HP::OOStudio::WorkflowBundle__');

	      my $driveDB = &getDB('drive');
			
		  if ( &os_is_windows() eq TRUE ) {
		    &__print_output("Mapping drive for access to extra long file paths encountered for << $sel >>", INFO);
			$oo_toplevel = $driveDB->set_drive("$oo_toplevel", undef, undef, undef, TRUE);
		    &__print_debug_output("OO Toplevel (REDUCED): $oo_toplevel") if ( $is_debug );
			$wfb->{'was_mapped_drive'} = TRUE if (&HP::Path::__is_only_letter_drive($oo_toplevel) eq TRUE );
	      }
			
		  $wfb->set_project_directory($oo_toplevel,
		                              $driveDB->expand_drivepath($oo_toplevel));  # Will populate with expected files...
		  $wfb->readbundle( TRUE, $hpoo_version );      # TRUE is for fast scan option

		  if ( &os_is_windows() eq TRUE ) {
		    &__print_output("Clearing mapped drive for << $sel >>", INFO);
			$driveDB->clear_drive($oo_toplevel);
			$wfb->project_directory($driveDB->collapse_drivepath($wfb->project_directory()));
		  }
			
		  $wfc->push_bundle($sel, $wfb);  # Store by nickname...
		  &remove_from_configuration('derived_data->oo_toplevel');
		} else {
		  &__print_output("Expected use case << $usecase >> has no ooflow directory???", FAILURE);
		}
	  } else {
	    &__print_output("Unable to find repo for file collection.  Looked at << $startdir >>!", FAILURE);
	  }
	}
	
	&save_to_configuration({'data' => [ "derived_data->cloudcapsule_$hpoo_version", $wfc ]});
	
	return $number_errors;
  }

#=============================================================================
sub determine_flows()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
	my $argsref = &get_from_configuration('program->user_arguments');
	my $derived = &get_from_configuration('derived_data');

	my $gds             = &get_global_datastore();
	my $capsule_manager = &get_capsule_data();
	
    $derived->{'user_stories'}->{'build'} = [];

    foreach ( @{$capsule_manager->usecase()->get_elements()} ) {
	  push ( @{$derived->{'user_stories'}->{'build'}}, $_->usecase());
	}
	
	return PASS;
  }
  
#=============================================================================
sub determine_subcapsules()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
	#my $argsref = &get_from_configuration('program->user_arguments');
	
	my $gds             = &get_global_datastore();
	my $capsule_manager = &get_capsule_data();
	
	my $failed_subcapsules = 0;
	
    foreach ( @{$capsule_manager->oo()->get_elements()} ) {
	  my $selection_name     = $_->name();  # Proper name already stored here.
	  my $provider_selection = $gds->get_matching_provider($selection_name);
	  
	  if ( not defined($provider_selection) ) {
	    &__print_output("Unable to find content based on $selection_name", FAILURE);
		++$failed_subcapsules;
		next;
	  }
	  
	  if ( ref($provider_selection) =~ m/^array/i ) {
	    &__print_output("Found multiple provider entries.  Cannot discern which is correct.  Please fix global data XML file!");
		++$failed_subcapsules;
		next;
	  }
	  
	  if ( defined($provider_selection->value()) ) {
	    #my $entry = $provider_selection->nickname() || $provider_selection->name();
		#&save_to_configuration({'table' => $derived, 'data' => [ "capsule_information->$entry", {}]});
		
		$_->allow_2_build( TRUE );
	  } else {
	    &__print_output("Unable to find associated tag for $selection_name!", WARN);
		++$failed_subcapsules;
	    next;
	  }
	}
	
	return PASS if ( $failed_subcapsules == 0 );
	return FAIL;
  }

#=============================================================================
sub produce_OO_capsule()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $capID   = shift || return FAIL;
	my $gds     = &get_global_datastore();
	
	my $capsule = $gds->get_matching_provider("$capID");
	my $usecase = $capsule->usecase() || $capsule->name();
	my $needs_building = $shared_flow_map_obj->available_for_building("$usecase");
	
	return PASS if ( $needs_building eq FALSE );

	my $hpoo_version = shift || return FAIL;

	my $buildpath = &get_from_configuration('program->user_arguments->build-path');
    my $ccc       = &get_from_configuration("derived_data->cloudcapsule_$hpoo_version");
	my $wfb       = $ccc->find_workflow_bundle("$capID");
	
	return FAIL if ( not defined($wfb) );
	
	my $capworkdir = &join_path("$buildpath", "CAPSULE-$capID");
	&delete("$capworkdir");
	&make_recursive_dirs("$capworkdir") if ( &does_directory_exist("$capworkdir") eq FALSE );
		
	my $error_status = $wfb->generate_jarfile("$capworkdir", "$capID");
	return $error_status if ( $error_status ne PASS );
	return PASS;
  }

#=============================================================================
sub produce_usecase_capsule
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $usecase   = shift || return FAIL;
	
	my $buildpath = &get_from_configuration('program->user_arguments->build-path');
    my $ucobj     = &get_capsule_data()->find_usecase_capsule("$usecase");

	if ( not defined($ucobj) ) {
	  &__print_output("Unable to find usecase capsule data for $usecase", FAILURE);
	  return FAIL;
	}
	my $error_status = $ucobj->generate_usecase_zip();
	return $error_status;
  }

#=============================================================================
sub read_capsule_directive()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
	my $argsref   = &get_from_configuration('program->user_arguments');
	my $buildpath = $argsref->{'build-path'};
	
	my $gdi       = &get_global_datastore();
	
	my $capxml    = &convert_path_to_client_machine($argsref->{'capsule-xml'}, &get_os_type());

	my $error_status = FAIL;
	
	goto COMPLETE_READ if ( &valid_string($capxml) eq FALSE );
	goto COMPLETE_READ if ( &does_file_exist("$capxml") eq FALSE );
	
	&save_to_configuration({'data' => [ 'derived_data->local->stories', {} ]});
	
	my $capdirective = &create_object('c__HP::Capsule::CapsuleDirective__');
	$capdirective->readfile("$capxml");
	$capdirective->store_localdata("$buildpath");
	
	if ( not defined(&query_jenkins('home')) ) {
	  $capdirective->analyze_local_data(OO_VERSION_10);  # Need to have this managed differently in the future!
	}
	
	my $usecase_list = $capdirective->usecase();
	my $oo_list      = $capdirective->oo();
	
	my $ldi = &get_local_datastore();
	foreach ( @{$usecase_list->get_elements()} ) {
	  my $made_oo_capsule = &get_template_obj($oo_list)->clone();
	  if ( not defined($made_oo_capsule) ) {
	    &__print_output("Unable to convert use-case information to oo information!", WARN);
		$error_status = FAIL;
		goto COMPLETE_READ;
	  }
	  
	  if ( not defined($_->usecase()) ) {
	    &__print_output('Unknown global mapping for < '. $_->name() .' >', FAILURE);
		$error_status = FAIL;
		goto COMPLETE_READ;
	  }
	  
	  $made_oo_capsule->convert_usecase_capsule($_);
	  $made_oo_capsule->get_parameters()->{'level'} = $capdirective->find_lowest_oo_level();
	  
	  $oo_list->push_item($made_oo_capsule);
	  &__print_output("Added < ". $_->usecase() ." > usecase to the list of buildable OO contents...");
	}

	$ldi->{'capsule_xml_directive'} = $capdirective;
	&__print_output("Completed reading/parsing << $capxml >>");
	$error_status = PASS;	
	
  COMPLETE_READ:
	return $error_status;
  }

#=============================================================================
sub run_capsule()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $argsref   = &get_from_configuration('program->user_arguments');
	my $derived   = &get_from_configuration('derived_data');
	my $buildpath = $argsref->{'build-path'};
	
	my $gds       = &get_global_datastore();	
    my $number_errors = 0;

	my $product_dir = &join_path($buildpath, $gds->get_build_parameter('package->productdir'));
    my $release_dir = &join_path($buildpath, $gds->get_build_parameter('package->releasedir'));
	
	if ( &lowercase_all("$product_dir") eq &lowercase_all("$buildpath") ) {
	  ++$number_errors;
	  &__print_output("Unable to ascertain product housing directory -- global data XML file may be corrupted", FAILURE);
	}
	
	if ( &lowercase_all("$release_dir") eq &lowercase_all("$buildpath") ) {
	  ++$number_errors;
	  &__print_output("Unable to ascertain release housing directory -- global data XML file may be corrupted", FAILURE);
	}
	
	return $number_errors if ( $number_errors > 0 );
	
	&delete("$product_dir") if ( &does_directory_exist("$product_dir") eq TRUE );
	&delete("$release_dir") if ( &does_directory_exist("$release_dir") eq TRUE );

    &__print_output("Reading capsule directive file...");
    ++$number_errors if ( &read_capsule_directive() eq FAIL );
	
	my $lds = &get_local_datastore();
	if ( not defined($lds->{'capsule_xml_directive'}) ) {
	  ++$number_errors;
	}
    return $number_errors if ( $number_errors > 0 );
	
    &__print_output("Running capsule building...");
	$number_errors += &determine_subcapsules();
	$number_errors += &determine_flows();
	
	my $capsule_manager  = &get_capsule_data();
	my @oo_capsules      = $capsule_manager->get_oo_capsule_ids();
	my @usecase_capsules = $capsule_manager->get_usecase_capsule_ids();
	
	my $totaljobs_subcapsules = scalar( @oo_capsules );
	my $totaljobs_flows       = scalar( @usecase_capsules );
	my $totaljobs             = $totaljobs_subcapsules + $totaljobs_flows;
	
	return $number_errors if ( $totaljobs_subcapsules == 0 && $totaljobs_flows == 0 );
	
	my $hpoo_versions = $argsref->{'hpoo'};
	
	my $number_errors_per_OO = {};
	
	foreach my $ooversion ( @{$hpoo_versions} ) {
	  $number_errors_per_OO->{"$ooversion"} = 0;
	  
	  &__print_output("Collecting necessary flows for OO capsule building << $ooversion >> [ Total jobs to process => $totaljobs ( $totaljobs_flows | $totaljobs_subcapsules ) ]...");
	  $number_errors_per_OO->{"$ooversion"} = &collect_capsule_contents($ooversion);
	  if ( $number_errors_per_OO->{"$ooversion"} > 0 ) {
	    &__print_output("Found issue attempting to prepare subcapsule content for << $ooversion >>!", FAILURE);
	    next;
	  }
	
	  # Loop over the capsules first..
	  foreach ( @oo_capsules ) {
	    my $oofailure = &produce_OO_capsule($_, $ooversion);  # Produces an OO Capsule
	    &__print_output("Failure detected in creation of $_...", WARN) if ( $oofailure > 0 );
		$number_errors_per_OO->{"$ooversion"} += $oofailure;
	  }
	
	  if ( $number_errors_per_OO->{"$ooversion"} > 0 ) {
	    &__print_output("Failure detected in creation of one or more OO capsules...", FAILURE);
        next;
	  }
	
	  foreach ( @usecase_capsules ) {
	    $number_errors_per_OO->{"$ooversion"} += &produce_usecase_capsule($_);  # Produces a Use Case Capsule
	  }

	  if ( $number_errors_per_OO->{"$ooversion"} > 0 ) {
	    &__print_output("Failure detected in creation of one or more UseCase capsules...", FAILURE);
        next;
	  }
	
	  # Build the capsule_pack metadata
	  $number_errors_per_OO->{"$ooversion"} += &build_bom($ooversion, \@oo_capsules);
	  
	  if ( $number_errors_per_OO->{"$ooversion"} > 0 ) {
	    &__print_output("Failure detected in creation of BOM...", FAILURE);
        next;
	  }

	  my $delivery_name = $capsule_manager->{'capsule_name'};
	  
	  my $releaseID = $argsref->{'releaseID'} || $gds->get_build_parameter('package->code_id');
	  my $finalized_name = undef;
	  if ( defined($delivery_name) ) {
	    $finalized_name = "$delivery_name\_$ooversion.zip";
	  } else {
	    $finalized_name = "$releaseID\_$ooversion\_CapsulePack.zip";
	  }
	  
	  &make_recursive_dirs("$release_dir") if ( &does_directory_exist("$release_dir") eq FALSE );
	  
	  my $zipobj = &create_object('c__HP::Zip::SevenZip__');
	  
	  # Allow for selection of associated contents (kept in global data area) as to what is built
	  # for this capsule so that multiple builds can be running in parallel
	  $zipobj->add_contents("$product_dir");
	  $zipobj->store_location(&join_path("$release_dir", "$finalized_name"));
	  $number_errors_per_OO->{"$ooversion"} = $zipobj->store();
	  
	  # Allow for generations of HPLN index files...
	  if ( exists($argsref->{'hpln-idx-gen'}) && $argsref->{'hpln-idx-gen'} eq TRUE ) {
	    my $hig = &create_object('c__HP::HPLN::IndexGenerator__');
		if ( not defined($hig) ) {
		  &__print_output("Requested HPLN index file generation, but was unable to comply!", WARN);
		} else {
		  my $hplnidxgenpath = &join_path($derived->{'devtools'}, 'library', 'oo', 'HPLN');
		  
		  # Need to allow for version to capture...
		  $hig->hpln_jarfile(&join_path("$hplnidxgenpath", 'hpln-index-generator-1.54.jar'));
		  $hig->index_directory(&normalize_path("$product_dir"));
		  
		  my $status = $hig->run();
		  
		  if ( $status ne PASS ) {
		    &__print_output("Unable to properly complete generating index files for all associated jarfiles found at << $product_dir >>!", WARN);
		  }
		}
	  }
    }
	
	foreach my $ooversion ( @{$hpoo_versions} ) {
	  $number_errors += $number_errors_per_OO->{"$ooversion"};
	}
	return $number_errors;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;