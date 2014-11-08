package HP::Capsule::CapsuleDirective;

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

    $VERSION = 0.75;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Configuration'   => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::String'                   => undef,
							'HP::CheckLib'                 => undef,
							'HP::Utilities'                => undef,
							
							'HP::Array::Tools'             => undef,
							'HP::CSL::Tools'               => undef,
							'HP::Path'                     => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsule_capsuledirective_pm'} ||
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
sub add_case
  {
	my $result = FALSE;
    my $self   = shift;
	my $obj    = shift || return $result;
	my $type   = shift;
	
	$type = $obj->get_type() if ( &is_type($obj, 'HP::Capsule::Common') eq TRUE );
	
	return $result if ( &valid_string($type) eq FALSE );
	return $result if ( &set_contains($type, $self->get_known_capsule_types()) eq FALSE );
	
	if ( &is_type($self->{$type}, 'HP::ArrayObject') eq TRUE ) {
	  $self->{$type}->push_item($obj);
	  $result = TRUE;
	}
	return $result;
  }

#=============================================================================
sub analyze_local_data
  {
    my $self      = shift;
	my $ooversion = shift;
	
	my $result       = &create_object('c__HP::Array::Set__');  # Full list...
	my $argsref      = &get_from_configuration('program->user_arguments');
	my $buildpath    = $argsref->{'build-path'};
	
	my $oo_only_list = &create_object('c__HP::Array::Set__');
	my $uc_only_list = &create_object('c__HP::Array::Set__');
	my $gds          = &get_global_datastore();

	my ($oo_cases, $use_cases, $missed_deps) = ( undef, undef, undef );
	
  RECHECK:
	$result->clear();
	$oo_only_list->clear();
	$uc_only_list->clear();
	$missed_deps = undef;
	
	$use_cases = $self->usecase()->get_elements();
	foreach ( @{$use_cases} ) {
	  if ( &is_type($_, 'HP::Capsule::UseCaseCapsule') eq TRUE ) {
	    my $localdata = undef;
		if ( ref($_->{'local_data'}) =~ m/ref/i ) {
	      $localdata = ${$_->{'local_data'}};
		} else {
	      $localdata = $_->{'local_data'};		
		}
		if ( defined($localdata) && &is_type($localdata, 'HP::CSL::DAO::LocalData') eq TRUE ) {
		  my $deps = $localdata->collect_all_dependencies($ooversion);
		  foreach my $dep_entry ( @{$deps} ) {
		    my $value = $dep_entry->value();
		    $result->push_item($value);
	      }
		}

		my $provider_selection = $gds->get_matching_provider($_->name());
		if ( defined($provider_selection) ) {
		  my $value = $provider_selection->value();
		  $uc_only_list->push_item($value);
		  #$result->delete_elements($value) if ( $result->contains($value) eq TRUE );
		}
	  }	  
	}
	
	foreach ( @{$uc_only_list->get_elements()} ) {
	  $result->delete_elements($_) if ( $result->contains($_) eq TRUE );
	}
	
	$oo_cases = $self->oo()->get_elements();
	foreach ( @{$oo_cases} ) {
	  if ( &is_type($_, 'HP::Capsule::OOCapsule') eq TRUE ) {
	    my $localdata = undef;
		if ( ref($_->{'local_data'}) =~ m/ref/i ) {
	      $localdata = ${$_->{'local_data'}};
		} else {
	      $localdata = $_->{'local_data'};		
		}
		if ( defined($localdata) && &is_type($localdata, 'HP::CSL::DAO::LocalData') eq TRUE ) {
		  my $deps = $localdata->collect_all_dependencies($ooversion);
		  foreach my $dep_entry ( @{$deps} ) {
		    my $value = $dep_entry->value();
		    $result->push_item($value);
	      }
		}
		
		my $provider_selection = $gds->get_matching_provider($_->name());
		if ( defined($provider_selection) ) {
		  $oo_only_list->push_item($provider_selection->value());
		}
	  }
	}
	
	$missed_deps = &set_symmetric_difference($result, $oo_only_list);
	
	if ( $missed_deps->number_elements() > 0 ) {
	  # Check to see that every entry in the dependency list is pushed into oo cases list
	  my $modified_build_contents = FALSE;
	  
	  foreach ( @{$missed_deps->get_elements()} ) {
	    my $dep_oo = &create_object('c__HP::Capsule::OOCapsule__');
		if ( not defined($dep_oo) ) {
		  &__print_output('Unable to instantiate necessary OO capsule for << '. $_ .' >>', WARN);
		  next;
		}
		
		my $provider_selection = $gds->get_matching_provider($_);
		next if ( defined($self->find_oo_capsule($provider_selection->name())) );
		
		$modified_build_contents = TRUE;
		&__print_output("Adding needed dependency : $_", INFO);
		$dep_oo->name($provider_selection->name());
		$dep_oo->usecase($provider_selection->usecase());
		
		$dep_oo->load_local_xmldata("$buildpath");

		my $ld_new = undef;
		if ( ref($dep_oo->{'local_data'}) =~ m/ref/i ) {
		  $ld_new = ${$dep_oo->{'local_data'}};
		} else {
		  $ld_new = $dep_oo->{'local_data'};
		}
		$dep_oo->version()->set_version($ld_new->get_build_parameter('csl->content->version'));
		$dep_oo->allow_2_build(TRUE);
		$dep_oo->get_parameters()->{'version'} = $dep_oo->version()->get_version();
		$self->oo()->push($dep_oo);
	  }
	  
	  goto RECHECK if ( $modified_build_contents eq TRUE );
	}
	
	return;
  }
  
#=============================================================================
sub data_types
  {
    my $self        = shift;
	my $which_level = shift || COMBINED;
	
    my $data_fields = {
					   'oo'          => '[HP::Array::Set] c__HP::Capsule::OOCapsule__',
					   'usecase'     => '[HP::Array::Set] c__HP::Capsule::UseCaseCapsule__',
					   'common_info' => 'c__HP::CSL::DAO::Section__',
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
sub find_lowest_oo_level
  {
    my $self   = shift;
	my $result = 1;     # base level
	my $level  = -1;    # initial value
	
	return $result if ( not exists($self->{'oo'}) );
	foreach ( @{$self->oo()->get_elements()} ) {
	  $level = $_->get_parameters()->{'level'};
	  next if ( &valid_string($level) eq FALSE );
	  next if ( &is_numeric($level) eq FALSE || $level < 0 );
	  $result = $level if ( $level > $result );
	}
	return $result;
  }
  
#=============================================================================
sub find_capsule_input_data
  {
    my $self           = shift;
	my $identification = shift;
	
	return undef if ( &valid_string($identification) eq FALSE );

	my $match = $self->find_oo_capsule($identification);
    $match = $self->find_usecase_capsule($identification) if ( not defined($match) );
	
	return $match;
  }

#=============================================================================
sub find_common_section
  {
    my $self = shift;
	my $key  = shift || return undef;
	
	my $section = $self->common_info()->configuration()->{"$key"};
	return $section if ( defined($section) );
	return undef;
  }

#=============================================================================
sub find_capsule
  {
    my $self   = shift;
	my $result = undef;
	
	my $identification = shift;
	my $key            = shift;
	
	return $result if ( &valid_string($identification) eq FALSE );
	
	my $capsule = $self->find_usecase_capsule("$identification", $key);
	if ( not defined($capsule) ) {
	  $capsule = $self->find_oo_capsule("$identification", $key);
	}
	
	return $capsule;
  }
  
#=============================================================================
sub find_oo_capsule
  {
    my $self   = shift;
	my $result = undef;
	
	my $identification = shift;
	my $key            = shift || 'name';
	
	return $result if ( &valid_string($identification) eq FALSE );
	return $result if ( not exists($self->{'oo'}) );
	
	$result = [];
	foreach ( @{$self->oo()->get_elements()} ) {
	  push( @{$result}, $_ ) if ( &equal($_->{"$key"}, "$identification") eq TRUE );
	}
	
	my $number_matches = scalar(@{$result});
	if ( $number_matches > 1 ) {
	  return $result;
	} elsif ( $number_matches == 1 ) {
	  return $result->[0];
    } else {
	  return undef;
	}
  }

#=============================================================================
sub find_usecase_capsule
  {
    my $self   = shift;
	my $result = undef;
	
	my $identification = shift;
	my $key            = shift || 'usecase';
	
	return $result if ( &valid_string($identification) eq FALSE );
	return $result if ( not exists($self->{'usecase'}) );
	
	$result = [];
	foreach ( @{$self->usecase()->get_elements()} ) {
	  push( @{$result}, $_ ) if ( &equal($_->{"$key"}, "$identification") eq TRUE );
	}
	
	my $number_matches = scalar(@{$result});
	if ( $number_matches > 1 ) {
	  return $result;
	} elsif ( $number_matches == 1 ) {
	  return $result->[0];
    } else {
	  return undef;
	}
  }
  
#=============================================================================
sub get_capsule_ids_by_type
  {
	my $result = &create_object('c__HP::Array::Set__');
    my $self   = shift;
	my $type   = shift || return $result->get_elements();
	my $drill  = shift || 'name';
	
	return $result->get_elements() if ( &set_contains($type, $self->get_known_capsule_types()) eq FALSE );
	
 	foreach ( @{$self->{$type}->get_elements()} ) {
	  my $data = undef;
	  $data = $_->{"$drill"} if ( exists($_->{"$drill"}) );
	  $result->push_item($data) if ( defined($data) );
	}
	
	return $result->get_elements();
  }
  
#=============================================================================
sub get_oo_capsule_ids
  {
    my $self = shift;
	return $self->get_capsule_ids_by_type('oo', 'name');
 }
  
#=============================================================================
sub get_usecase_capsule_ids
  {
    my $self = shift;
	return $self->get_capsule_ids_by_type('usecase', 'usecase');
  }

#=============================================================================
sub get_all_subcapsules
  {
    my $self   = shift;
	my $result = &create_object('c__HP::Array::Set__');
	
	my $oo_contents = $self->get_oo_capsule_ids();
	$result->add_elements({'entries' => $oo_contents});
	
	return $result->get_elements();
  }
  
#=============================================================================
sub get_known_capsule_types
  {
	return [ 'oo', 'usecase' ];
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
sub number_cases
  {
    my $self = shift;
	my $type = shift || 'all';
	
	my $count = 0;
	my $capsule_list = [];
	
	return $count if ( &set_contains($type, &set_union($self->get_known_capsule_types(), 'all', TRUE)) eq FALSE );
	if ( $type eq 'all' ) {
	  $capsule_list = $self->get_known_capsule_types();
	} else {
	  $capsule_list = &convert_to_array("$type", TRUE);
	}
	
	foreach ( @{$capsule_list} ) {
	  $count += $self->{"$_"}->number_elements();
	}
	return $count;
  }
  
#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	
	$self->update();
	return;
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub store_localdata
  {
    my $self            = shift;
	my $buildpath       = shift || return;
	
	foreach ( @{$self->oo()->get_elements()} ) {
	  $_->load_local_xmldata("$buildpath");
	}
	
	# Would like to be able to reference the appropriate local data storage areas
	# from the OO capsules for the usecase capsules.  Need to make sure I have the
	# proper naming conventions to handle this.
	foreach ( @{$self->usecase()->get_elements()} ) {
	  $_->load_local_xmldata("$buildpath");
	}
  }
  
#=============================================================================
1;