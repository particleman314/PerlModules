package HP::CSL::DAO::LocalData;

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
    use lib "$FindBin::Bin/../../..";

	use parent qw(HP::CSL::DAO::Data);
	
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

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'                  => undef,
							'HP::Support::Base'              => undef,
							'HP::Support::Base::Constants'   => undef,
							'HP::Support::Hash'              => undef,
	                        'HP::CheckLib'                   => undef,
							'HP::Support::Configuration'     => undef,
							'HP::Support::Os'                => undef,
							'HP::Support::Object::Tools'     => undef,
							'HP::Support::Object::Constants' => undef,
							'HP::Array::Constants'           => undef,
							'HP::Array::Tools'               => undef,
							
							'HP::String'                     => undef,
							'HP::String::Constants'          => undef,
							
							'HP::Path'                       => undef,
							'HP::FileManager'                => undef,
							'HP::Os'                         => undef,
							
							'HP::CSL::Tools'                 => undef,
							'HP::CapsuleMetadata::UseCase::Constants' => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_csl_dao_localdata_pm'} ||
                 $ENV{'debug_csl_dao_modules'} ||
				 $ENV{'debug_csl_modules'} ||
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
sub add_metadata
  {
    my $self     = shift;
	my $metadata = shift || return FALSE;
	my $type     = shift || return FALSE;
	
	$self->{'metadata'} = {} if ( not exists($self->{'metadata'}) );
	$self->{'metadata'}->{"$type"} = $metadata;
	
	return TRUE;
  }
  
#=============================================================================
sub cleanup_internals
  {
    my $self = shift;
    my $internal_fields   = [ ];
    my $additional_method = {
                              'use_interior_nodes' => [REMOTE, 'HP::Utilities', 'delete_field'],
                            };

    return &HP::Support::Object::__cleanup_internals($self, $internal_fields, $additional_method);
  }

#=============================================================================
sub collect_all_service_design_names
  {
    my $result = &create_object('c__HP::Array::Set__');
	
    my $self          = shift;
	my $add_extension = shift || FALSE;
	
	my $sds    = $self->installerData()->serviceblueprints()->blueprint();
	
	foreach ( @{$sds->get_elements()} ) {
	  my $name = $_->name();
	  $name .= '.zip' if ( $add_extension eq TRUE );
	  $result->push_item($name);
	}
	
	return $result->get_elements();
  }

#=============================================================================
sub collect_all_service_designs
  {
    my $result = &create_object('c__HP::Array::Set__');
    my $self   = shift;
	my $sds    = $self->installerData()->serviceblueprints()->blueprint();
	
	foreach ( @{$sds->get_elements()} ) {
	  $result->push_item({'name' => $_->name(), 'version' => $_->version(), 'association' => $_->association()});
	}
	
	return $result->get_elements();
  }
  
#=============================================================================
sub collect_all_OOTB_artifacts
  {
    my $result    = &create_object('c__HP::ArrayObject__');
    my $self      = shift;
	my $ooversion = shift || return $result->get_elements();
	my $sds       = $self->installerData()->serviceblueprints()->blueprint();
	
	return $result->get_elements() if ( $sds->number_elements() == 0 );
	
	# Loop over each service blueprint
	foreach ( @{$sds->get_elements()} ) {
	
	  # Loop over the dependencies section for each service blueprint
	  foreach my $dep ( @{$_->dependencies()->get_elements()} ) {
	  
	    # Loop over each dependency type
	    foreach my $deptype ( @{$dep->deptypes()->get_elements()} ) {
		
		  # Only select "ooflow" dependencies
		  if ( &is_type($deptype, 'HP::CapsuleMetadata::UseCase::DependencyTypes::ooflow') eq TRUE ) {
		  
		    # Make sure the version of the OOtag is what is expected
		    if ( $deptype->tag() eq $ooversion ) {
		      foreach my $artifact ( @{$deptype->artifacts()->get_elements()} ) {
			  
			    # Make sure the artifact is one which is labeled as OOTB
			    $result->push_item( $artifact ) if ( $artifact->type() eq OOTB );
			  }
			}
		  }
		}
	  }
	}
	
	return $result->get_elements();
  }

#=============================================================================
sub collect_all_dependencies
  {
    my $self         = shift;
	my $oo_version   = shift || undef;
	my $associations = undef;
	
	$associations = $self->FlowDependencies()->get_flow_deps($oo_version);
	return $associations;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
					   'installerData'    => 'c__HP::CapsuleMetadata::UseCase::InstallerData__',
					   'PDTData'          => 'c__HP::CapsuleMetadata::OO::InstallerData__',
					   'FlowDependencies' => 'c__HP::CapsuleMetadata::OO::FlowDependency__',
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
sub get_service_design_entry
  {
    my $self   = shift;
	my $result = undef;
	my $usersd = shift || return $result;
	
	my $sds    = $self->installerData()->serviceblueprints()->blueprint();
	
	foreach ( @{$sds->get_elements()} ) {
	  if ( $usersd eq $_->name() ) {
	    $result = $_;
		last;
	  }
	}
	
	return $result;
  
  }
  
#=============================================================================
sub has_service_design_entry
  {
    my $self   = shift;
	my $result = FALSE;
	my $usersd = shift || return $result;
	
	my $sds    = $self->installerData()->serviceblueprints()->blueprint();
	
	foreach ( @{$sds->get_elements()} ) {
	  if ( $usersd eq $_->name() ) {
	    $result = TRUE;
		last;
	  }
	}
	
	return $result;
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
	$self->os(&get_os_type());
	return $self;  
  }

#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	delete($self->{'release_matrix'});
	
	my $gds = &get_from_configuration('derived_data->global') || &get_global_datastore();
	return FALSE if ( not defined($gds) );
	
	my $hm = $self->get_build_parameter('human->name');
	if ( &valid_string($hm) eq FALSE ) {
	  &__print_output("Unable to complete post callback read since no HUMAN-NAME field found", WARN);
	  return FALSE;
	}
	
	my $capsule = $gds->get_matching_provider($hm);
	if ( defined($capsule) ) {
	  $self->set_build_parameter('csl->content->working_base', $capsule->workflow()) if ( defined($capsule->workflow()) );
	}
	
	return TRUE;
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
1;