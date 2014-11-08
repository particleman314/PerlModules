package HP::OOStudio::WorkflowBundle;

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

	use parent qw(HP::BaseObject HP::XML::XMLEnableObject);
	
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

    $VERSION = 0.95;

    @EXPORT  = qw (
                  );

    $module_require_list = {
	                        'Cwd'                          => undef,
							'File::Basename'               => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
	                        'HP::CheckLib'                 => undef,

							'HP::Support::Object::Tools'   => undef,
							'HP::Support::Configuration'   => undef,
							'HP::Array::Constants'         => undef,
							'HP::Array::Tools'             => undef,
							'HP::XML::Constants'           => undef,
							
							'HP::OOStudio::Tools'          => undef,
							'HP::OOStudio::Constants'      => undef,
							'HP::Capsule::Tools'           => undef,
							'HP::CSL::Tools'               => undef,
							'HP::UUID::Tools'              => undef,
							'HP::UUID::Constants'          => undef,
							
							'HP::Stream::Constants'        => undef,
							'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
							'HP::Copy'                     => undef,
							'HP::Timestamp'                => undef,
							'HP::DBContainer'              => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_oostudio_workflowbundle_pm'} ||
				 $ENV{'debug_oostudio_modules'} ||
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
my $uuid_record_file = 'recorded_uuids.xml';

#=============================================================================
sub collect_files
  {
    my $self   = shift;
	my $srcdir = shift || $self->mapped_directory()->{'driveletter'} || $self->project_directory();
	
	if ( &valid_string($srcdir) eq TRUE &&
	     &does_directory_exist("$srcdir") eq TRUE ) {
	
	  &ignore_hidden('directories', TRUE);
	  &ignore_hidden('files', TRUE);
	  
	  &__print_debug_output("Src directory is --> $srcdir", __PACKAGE__) if ( $is_debug );
	  my $result = &collect_all_files("$srcdir", {'function' => \&is_xml_file});
	  if ( scalar(@{$result}) > 0 ) {
	    $self->project_files()->add_elements({'entries' => $result});
	  }
	}
	
	return;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'mapped_directory'  => {},
	                   'project_directory' => undef,
					   'project_files'     => 'c__HP::ArrayObject__',
		              };
    
	if ( $which_fields eq COMBINED ) {
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
sub generate_bundle_uuid
  {
    my $self = shift;
	my $uuid_array = &create_object('c__HP::ArrayObject__');
	
	my $uuidDB = &getDB('uuid');
	
	my $content = $self->get_uuids();
	$uuidDB->add_uuid_list($content->[1]) if ( defined($uuidDB) );
	
	$uuid_array->add_elements({'entries' => $uuidDB->get_uuids()});
	
	my $best_uuid = &generate_unique_uuid($uuid_array);
	
	$self->{'uuid'} = $best_uuid;
	$uuidDB->add_jarfile_uuid($best_uuid);
	return;
  }
  
#=============================================================================
sub generate_jarfile
  {
    my $result = FAIL;
    my $self   = shift;
	my $jardir = shift || return $result;
	my $capID  = shift || return $result;
	
	return $result if ( &does_directory_exist("$jardir") eq FALSE );
	
	&__print_output("Producing jarfile for $capID", INFO);

	$result = $self->writebundle("$jardir");
	if ( $result eq FAIL ) {
	  &__print_output("Unable to properly write the OO flow bundle...", FAILURE);
	  return $result;
	}
	
	$self->generate_bundle_uuid();
	
	my $strDB = &getDB('stream');
	
	# Touch these files
	$strDB->touch_file(&join_path("$jardir", 'Lib', 'dummy.txt'));
	$strDB->touch_file(&join_path("$jardir", 'META-INF','MANIFEST.MF'));

	my $derived   = &get_from_configuration('derived_data');
	my $buildpath = &get_from_configuration('program->user_arguments->build-path');
	
	my $capsule_manager  = &get_capsule_data();

	my $capsule  = $capsule_manager->find_oo_capsule("$capID");
	my $provider = &get_matching_provider("$capID");
	
	if ( ref($provider) =~ m/^array/i ) {
	  &__print_output("Found multiple provider matches.  Cannot handle this scenario!", FAILURE);
	  return $result;
	}
	
	if ( (not defined($capsule)) && defined($provider) ) {
	  $capsule = $capsule_manager->find_oo_capsule($provider->usecase());
	  if ( not defined($capsule) ) {
	    &__print_output("Unable to find use necessary capsule data for << $capID >>");
		return $result;
	  }
	  $capsule->name($provider->name());
	}
	
	my $localdata = &get_local_data_for_usecase($provider->usecase());
	my $cpprops   = $self->generate_properties_file($provider, $capsule, $localdata);
	
	&__print_output("\nContent pack information --> \n\n$cpprops\n");
	my $propstream = $strDB->make_stream(&join_path("$jardir", 'contentpack.properties'), OUTPUT, '__PROPERTIES__');
	$propstream->raw_output($cpprops);
	$strDB->remove_stream('__PROPERTIES__');
	
	$result = &copy_with_rsync(
	                           &join_path("$jardir", 'contentpack.properties'),
	                           &join_path("$jardir", 'resource-bundles', 'cp.properties')
					          );
	if ( $result ne TRUE ) {
	  &__print_output("Failure in copy of properties files for jarfile creation", FAILURE);
	  return FAIL;
    }	
	
	my $translated_name = &generate_capsule_name($provider, $capsule, $localdata);
	
	my $gdi = &get_global_datastore();
	
	my $product_dir = &join_path("$buildpath", $gdi->get_build_parameter('package->productdir'));
	&make_recursive_dirs("$product_dir") if ( &does_directory_exist("$product_dir") eq FALSE );
	
	my $oo_metadata = &create_object('c__HP::CapsuleMetadata::OO__');
	if ( not defined($oo_metadata) ) {
	  &__print_output("Unable to generate OO capsule metadata file", FAILURE);
	  return FAIL;
	}
	
	my $capversion  = &generate_version($provider, $capsule, $localdata);

	my $installdata = $oo_metadata->installerData();
	$installdata->name($provider->value());
	$installdata->displayName($translated_name);
	$installdata->description(&generate_description($provider, $capsule, $localdata));
	$installdata->publisher(&generate_publisher($provider, $capsule, $localdata));
		
	my $vobj = &create_object('c__HP::VersionObject__');
	$vobj->set_version("$capversion");
	# Suppress writing comparison out as attribute
	$vobj->{SUPPRESSION_KEY} = [ 'comparison' ];
	
	$installdata->version($vobj);
	
	if ( defined($localdata) ) {
	  my $ooengines = $localdata->{'PDTData'}->ooengines();
	  $installdata->ooengines($ooengines->clone()) if ( defined($ooengines) );
	  
	  $installdata->dependencies($localdata->{'FlowDependencies'});
	  $localdata->add_metadata($oo_metadata, 'oo');
	} else {
	  &__print_output("Unable to find local data XML file for $capID", WARN);
	}
	$oo_metadata->write_xml(&join_path("$jardir", 'provider_capsule.manifest'));
	
	# Zip of the content and return...
	my $finalized_name  = $provider->value().".jar";
	my $zipobj = &create_object('c__HP::Zip::SevenZip__');
	
	# Add contents not actual directory which adds another level which is not requested
	$zipobj->add_contents("$jardir");
	
	# Store the contents into the jarfile...
	my $zipname = &join_path("$product_dir", "$finalized_name");
	$zipobj->store_location("$zipname");
	
	$result = $zipobj->store();
	&delete("$jardir");

	if ( defined($localdata) ) {
	  $localdata->add_parameter('produced_jarname', "$finalized_name") if ( $result eq PASS );
    }
	
	my $tagid = $provider->usecase();
	
	$gdi->{'produced_items'} = {} if ( not defined($gdi->{'produced_items'}) );
	$gdi->{'produced_items'}->{$tagid} = &create_object('c__HP::Array::Set__') if ( not defined($gdi->{'produced_items'}->{$tagid}) );
	$gdi->{'produced_items'}->{$tagid}->push_item("$zipname");
	
	$self->save_uuids();

	return FAIL if ( $result ne PASS );
	return PASS;
  }
  
#=============================================================================
sub generate_properties_file
  {
    my $self      = shift;
	
	my $provider  = shift;
	my $capsule   = shift;
	my $localdata = shift || &create_object('c__HP::CSL::DAO::LocalData__');
	
	return if ( &is_type($provider, 'HP::Providers::Common') eq FALSE );
	return if ( &is_type($capsule, 'HP::Capsule::Common') eq FALSE );
	
	$self->generate_bundle_uuid() if ( not exists($self->{'uuid'}) );
	
	my $cpprops = '';
	
	$cpprops .= '#'.                         &get_formatted_datetime() ."\n";
	$cpprops .= 'content.pack.name='.        &generate_capsule_name($provider, $capsule, $localdata). "\n";
	$cpprops .= 'content.pack.uuid='.        $self->uuid() ."\n";         # Should be a version 4 UUID
	$cpprops .= 'content.pack.version='.     &generate_version($provider, $capsule, $localdata) ."\n";
	$cpprops .= 'content.pack.publisher='.   &generate_publisher($provider, $capsule, $localdata) ."\n";
	$cpprops .= 'content.pack.description='. &generate_description($provider, $capsule, $localdata) ."\n";
	
	return $cpprops;
  }

#=============================================================================
sub get_uuids
  {
    my $self             = shift;
	my $total_uuids      = [];
	my $uuid_association = {};
	
	my $pd = $self->project_directory();

    if ( $self->{'has_uuid_xmlfile'} eq FALSE ||
	     ( ($self->{'has_uuid_xmlfile'} eq TRUE) &&
		   ($self->{'uuidxml_outofdate'} eq TRUE) ) ) {
	  foreach ( @{$self->project_files()->get_elements()} ) {
	    if ( &is_blessed_obj($_) eq TRUE ) {
	      my $uuid_list = $_->get_uuids($self->{'fast_scan'});
		  $total_uuids  = &set_union($total_uuids, $uuid_list);
		  foreach my $uuid ( @{$uuid_list} ) {
		    if ( exists($uuid_association->{$uuid}) ) {
		      &__print_output("Found a pre-existing UUID -> OLD ==> $uuid_association->{$uuid} : NEW $_", FAILURE);
			  next;
		    }
		    $uuid_association->{$uuid} = $_->filename();
		  }
	    }
	  }
	  my $uuidfilelist = &create_object('c__HP::UUID::UUIDFileList__');
	  $uuidfilelist->add_uuid_list($uuid_association);
	  $self->{'uuidxml'} = $uuidfilelist;
	} else {
	  $total_uuids = $self->{'uuidxml'}->get_elements();
	  foreach ( @{$self->{'uuidxml'}->uuid_association()->get_elements()} ) {
	    $uuid_association->{$_->uuid()} = $_->filename();
	  }
	}
	
	return [ $total_uuids, $uuid_association ];
  }
  
#=============================================================================
sub has_uuid
  {
    my $self = shift;
	my $uuid_to_check = shift || return FALSE;
	
	my $uuid_array = &create_object('c__HP::ArrayObject__');
	$uuid_array->add_elements({'entries' => $self->get_uuids()});
	
	return $uuid_array->contains($uuid_to_check);
  }
  
#=============================================================================
sub number_files
  {
    my $self = shift;
	return $self->project_files()->number_elements();
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
		  if ( exists($self->{"$key"}) ) { $self->{"$key"} = $_[0]->{"$key"}; }
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
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub push_file
  {
    my $self = shift;
	my $filename = shift || return;
	
	return if ( &valid_string("$filename") eq FALSE );
	$self->project_files()->push_item("$filename");
	return;
  }
  
#=============================================================================
sub readbundle
  {
    my $self            = shift;	
	my $allow_fast_scan = shift || FALSE;
	my $type            = shift || OO_VERSION_10;
	
	$self->{'fast_scan'} = $allow_fast_scan;
	
	my $result = TRUE;
	
	my $pd = $self->project_directory();	
	$pd = &getcwd() if ( &valid_string($pd) eq FALSE );
	&__print_output("Project directory for reading content bundle : $pd",INFO);
	
	my $driveDB = &getDB('drive');

	my $uuidxmlmt = undef;
	my $uuidrecordfile = &join_path(File::Basename::dirname("$pd"), "$uuid_record_file");
	$uuidrecordfile = $driveDB->collapse_drivepath("$uuidrecordfile");
	
	# TODO -- Need to figure out why uuidrecordfile is not being used properly...
	if ( 0 ) {
	  &__print_output("Reading uuid record XML file << $uuidrecordfile >>", INFO);
	  if ( &does_file_exist("$uuidrecordfile") ) {
	    my $uuidlist = &create_object('c__HP::UUID::UUIDFileList__');
	    $uuidlist->readfile("$uuidrecordfile");
	  
	    if ( (&valid_string($uuidlist->jarfile_uuid()) eq FALSE) ||
	         ($uuidlist->jarfile_uuid() eq ZERO_UUID) ) {
		  $self->{'has_uuid_xmlfile'}  = FALSE;
	    } else {
	      $uuidxmlmt = $uuidlist->modify_date();
	      $self->{'has_uuid_xmlfile'}  = TRUE;
	      $self->{'uuidxml_outofdate'} = FALSE;
	      $self->{'uuidxml'}           = $uuidlist;
	    }
	  } else {
	    $self->{'has_uuid_xmlfile'} = FALSE;
	  }
	} else {
	  $self->{'has_uuid_xmlfile'} = FALSE;
	}
	
	my $pf = $self->project_files();
	if ( scalar(@{$pf->get_elements()}) < 1 ) {
	  &__print_output("Begin scanning bundle...", INFO);
	  my $all_files = &collect_all_files($self->project_directory(), {'function' => \&is_xml_file});
	  &__print_output("Number of files found during scan : " . scalar( @{$all_files} ), INFO);
	  $pf->add_elements({'entries' => $all_files});
	}
	
	&__print_output("Total Number of files found : " . scalar( @{$pf->get_elements()} ), INFO);
	for( my $loop = 0; $loop < scalar( @{$pf->get_elements()} ); ++$loop ) {
	  my $loop_cnt = 0;
	  my $path = $pf->get_element($loop);

	TRY_AGAIN:
	  ++$loop_cnt;
	  if ( &does_file_exist("$path") eq FALSE && $loop_cnt > 2 ) {
	    $path = &join_path("$pd", "$path");
		goto TRY_AGAIN;
	  } else {
	    if ( $loop_cnt > 2 ) {
	      &print_output("Cannot find file << $path >> to process", FAILURE);
		  next;
		}
	  }

	  my $obj = &create_object('c__HP::OOStudio::OOStudioFile__');
	  $obj->oostudio_type($type);
	  
	  if ( defined($uuidxmlmt) ) {
	    if ( defined($self->{'uuidxml_outofdate'}) && $self->{'uuidxml_outofdate'} eq FALSE ) {
	      my $filetime = &get_file_time("$path");
	      $self->{'uuidxml_outofdate'} = TRUE if ( $filetime > $uuidxmlmt );
	    }
	  }
	  
	  if ( defined($obj) ) {
	    my $individual_result = $obj->readfile( &path_to_unix("$path"), $allow_fast_scan );
	    if ( $individual_result eq FALSE ) {
	      &__print_output("Unable to read workflow file << $path >>!", WARN);
		  next;
	    }
		$pf->set_element($loop, $obj); # Replace filename with actual OOStudioFile object
		$result = $result & $individual_result;
	  }
    }
	
	return $result;
  }
  
#=============================================================================
sub save_uuids
  {
    my $self = shift;
	my $pd   = shift || $self->project_directory();
	
	my $dirabove = File::Basename::dirname("$pd");
	my $uuidfile = &join_path("$dirabove", "$uuid_record_file");
	
	my $uuidlist = &create_object('c__HP::UUID::UUIDFileList__');
	if ( ($self->{'has_uuid_xmlfile'} eq FALSE) ||
	     ( ($self->{'has_uuid_xmlfile'} eq TRUE) &&
		   ($self->{'uuidxml_outofdate'} eq TRUE ) ) ) {
	  $uuidlist->jarfile_uuid($self->{'uuid'});
	  $uuidlist->add_file_uuids($self->get_uuids());  # First element is list of UUIDs, Second element is hash of UUID to file
	  
	  &delete("$uuidfile");
	  $uuidlist->modify_date(time());
	  $uuidlist->write_xml("$uuidfile", 'uuidlist');
	}
	return;
  }
  
#=============================================================================
sub set_project_directory
  {
    my $self       = shift;
	my $reduced_pd = shift;
	my $pd         = shift || return;
	
	&__print_output("Setting project directory as [ $pd, $reduced_pd ]", INFO);
	if ( &does_directory_exist("$pd") eq TRUE ) {
	  $self->project_directory("$pd");
	  $self->mapped_directory()->{'driveletter'} = "$reduced_pd";
	  $self->mapped_directory()->{'driveletter_map'} = "$pd";
	  
	  $self->project_files->clear();
	  $self->collect_files();
	}
  }
  
#=============================================================================
sub validate
  {
    my $self = shift;
	return;
  }
  
#=============================================================================
sub writebundle
  {
    my $self                 = shift;
	my $destination_toplevel = shift || &getcwd();
	my $result               = TRUE;
	
	my $pf = $self->project_files()->get_elements();
	&__print_output("Project file count : ". scalar(@{$pf}), INFO);
	return $result if ( scalar(@{$pf}) < 1 );

	my $pd = $self->project_directory();
 	my $driveDB = &getDB('drive');
	
	&__print_output("Project directory for writing jarfile bundle : $pd", INFO);
	if ( &does_directory_exist("$pd") eq TRUE ) {
	  my $contents = &collect_directory_contents("$pd");
	  foreach ( @{$contents->{'directories'}} ) {
	    $result &= &copy_with_rsync(&join_path("$pd", "$_"), "$destination_toplevel");
	  }	  
	} else {
	  $destination_toplevel = &path_to_unix("$destination_toplevel");

	  for( my $loop = 0; $loop < scalar( @{$pf} ); ++$loop ) {
	    next if ( &is_blessed_obj($pf->[$loop]) eq FALSE ||
	              &is_type($pf->[$loop], 'HP::OOStudio::OOStudioFile') eq FALSE );
	  
	    my $fullpath = $pf->[$loop]->filename();
	    next if ( &valid_string($fullpath) eq FALSE );
	  	  
	    my $individual_result = FALSE;
	  
	    $fullpath = $driveDB->collapse_drivepath("$fullpath");
	    $fullpath = $driveDB->__divide_and_conquer("$fullpath");
	  
	    if ( &does_file_exist("$fullpath") eq TRUE ) {
		   
		  &make_recursive_dirs("$destination_toplevel") if ( &does_directory_exist("$destination_toplevel") eq FALSE );
	      $individual_result = &copy_with_rsync("$fullpath", "$destination_toplevel");
		
	    } else {
	      $individual_result = $pf->[$loop]->write_xml();
	    }
	  
	    if ( $individual_result eq FALSE ) {
	      &__print_output("Unable to write workflow file << $fullpath >>!", WARN);
	    }
	    $result = $result & $individual_result;
      }
	}
	
	return ( $result ) ? PASS : FAIL;	
  }
  
#=============================================================================
1;