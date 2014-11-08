package HP::CSL::DAO::GlobalData;

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

    $VERSION = 1.00;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
	                        'HP::CheckLib'                 => undef,
							'HP::Support::Configuration'   => undef,
							'HP::Support::Os'              => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Array::Constants'         => undef,
							'HP::Array::Tools'             => undef,
							
							'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
							'HP::Os'                       => undef,
							'HP::CapsuleMetadata::UseCase::Constants' => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_csl_dso_globaldata_pm'} ||
                 $ENV{'debug_csl_dso_modules'} ||
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
sub __get_xml_translation_map
  {
    my $self = shift;
    my $translation_map = {
                           &BACKWARD => {
                                         'provider_list'  => 'providerMapping',
										 'support_matrix' => 'supportMatrix',
                                        },
                          };
    my %hash = %{$translation_map->{&BACKWARD}};
    my %hsah = reverse %hash;

    $translation_map->{&FORWARD} = \%hsah;
    return $translation_map;
  }

#=============================================================================
sub collect_global_OOTB_artifacts
  {
    my $result      = &create_object('c__HP::ArrayObject__');
    my $self        = shift;
	my $ooversion   = shift || return $result->get_elements();
	my $global_ootb = $self->global_dependency();
	
	return $result->get_elements() if ( $global_ootb->number_elements() == 0 );
	
	# Loop over each service blueprint
	foreach ( @{$global_ootb->get_elements()} ) {
	
	  # Loop over each dependency type
	  foreach my $deptype ( @{$_->deptypes()->get_elements()} ) {
		
		# Only select "ooflow" dependencies
		if ( &is_type($deptype, 'HP::CapsuleMetadata::UseCase::DependencyTypes::ooflow') eq TRUE ) {
		  
		  # Make sure the version of the OOTag is what is expected
		  if ( $deptype->tag() eq $ooversion ) {
		    foreach my $artifact ( @{$deptype->artifacts()->get_elements()} ) {
			  $artifact->version()->modify_output_representation_all_fields();
			  
			  # Make sure the artifact is one which is labeled as OOTB
			  $result->push_item( $artifact ) if ( $artifact->type() eq OOTB );
			}
		  }
		}
	  }
	}
	
	return $result->get_elements();
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'providerMapping'   => 'c__HP::ProviderList__',
					   'tiertable'         => 'c__HP::CapsuleMetadata::CloudCapsule::TierTable__',
					   'installer_section' => 'c__HP::CSL::DAO::Section__',
					   'test_section'      => 'c__HP::CSL::DAO::Section__',
					   'global_dependency' => '[] c__HP::CapsuleMetadata::UseCase::Dependency__',
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
sub get_ignored_content
  {
    my $self = shift;
	my $data = $self->get_build_parameter('build->ignored->content->name');
	return [] if ( not defined($data) );
	return $data;
  }
  
#=============================================================================
sub get_ignored_lrc
  {
    my $self = shift;
	my $data = $self->get_build_parameter('build->ignored->lrc->name');
	return [] if ( not defined($data) );
	return $data;
  }
  
#=============================================================================
sub get_installer_parameter
  {
    my $self  = shift;
	my $param = shift || return undef;
	my $other_sections = shift || [];

	return $self->__get_parameter('installer', $param, $other_sections);
  }
  
#=============================================================================
sub get_package_parameter
  {
    my $self  = shift;
	my $param = shift || return undef;
	my $other_sections = shift || [];

	return $self->__get_parameter('package', $param, $other_sections);
  }
  
#=============================================================================
sub get_matching_provider
  {
    my $self            = shift;
	my $matching_id     = shift;
  	my $provider_matrix = $self->get_provider_list();
	return undef if ( not defined($provider_matrix) );
	
	my $provider = $provider_matrix->find_provider("$matching_id");
	
    if ( defined($provider) ) {
	  if ( $provider->number_elements() == 1 ) {
	    $provider = $provider->get_element(0);
	  }
	}
	
	return $provider;
  }
  
#=============================================================================
sub get_normalized_provider_name
  {
    my $self           = shift;
	my $identification = shift || return undef;
	
	my $provider      = $self->get_matching_provider("$identification");
	return undef if ( not defined($provider) );
	
	my $response_type = &is_type($provider, 'HP::Array::Set');
	
	# Fully qualified name [ all entries have one ]	
	return $provider->name() if ( $response_type eq FALSE );
	if ( $response_type eq TRUE ) {
	  my @result = ();
	  foreach ( @{$provider->get_elements()} ) {
	    push ( @result, $_->name() );
	  }
	  return \@result;
	}
	return undef;
  }
  
#=============================================================================
sub get_tier_table
  {
    my $self = shift;
	my $data = $self->tiertable();
	
	if ( not defined($data) ) {
	  &__print_output("Unable to extract Global Datastore.  Please check to see if it was loaded!", WARN);
	  return undef;
	}
	
	return $data;
  }
  
#=============================================================================
sub get_provider_list
  {
    my $self = shift;
	my $data = $self->providerMapping();
	
	if ( not defined($data) ) {
	  &__print_output("Unable to extract Global Datastore.  Please check to see if it was loaded!", WARN);
	  return undef;
	}
	
	return $data;
  }
  
#=============================================================================
sub get_test_parameter
  {
    my $self  = shift;
	my $param = shift || return undef;
	my $other_sections = shift || [];

	return $self->__get_parameter('test', $param, $other_sections);
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
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub replace_configuration_items
  {
    my $self = shift;
	my $item = shift;
	my $other_sections = shift || [];
	
	return undef if ( not defined($item) );
	
	my $config_sections = [];
	push(@{$config_sections}, &get_configuration());
	
	my @key_types = keys(%{$self->data_types()});
	foreach ( @key_types ) {
	  push( @{$config_sections}, $self->{"$_"}->configuration() ) if ( &is_type($self->{"$_"}, 'HP::CSL::DAO::Section') eq TRUE );
	}
	foreach ( @{$other_sections} ) {
	  push( @{$config_sections}, $_ );
	}
	
	my $changed = FALSE;
	my $ref_type = ref($item);
	
	if ( $ref_type eq '' ) {
	  &__print_debug_output("(B) $item ++++", __PACKAGE__) if ( $is_debug );
	  my $begin_marker = &convert_to_regexs('{');
	  my $end_marker   = &convert_to_regexs('}');
		
      return ($item, $changed) if ( $item !~ m/$begin_marker/ );
      return ($item, $changed) if ( $item !~ m/$end_marker/ );
	  
	  if ( $item =~ m/(\S*)$begin_marker(\S*)$end_marker(\S*)/ ) {
        my $begin = $1;
        my $end   = $3;
        my $replacement = $2;

        my $substitution = undef;
		my $replaced = FALSE;
		foreach ( @{$config_sections} ) {
		  $substitution = &get_from_configuration($replacement, TRUE, $_);
		  if ( defined($substitution) ) {
		    $item =~ s/${begin_marker}${replacement}${end_marker}/${substitution}/;
			$replaced = TRUE;
			last;
		  }
		}
		
		if ( $replaced eq FALSE ) {
		  $item =~ s/${begin_marker}${replacement}${end_marker}//;
		}
		$changed = TRUE;
	  }
	  &__print_debug_output("(A) $item ++++", __PACKAGE__) if ( $is_debug );
    } elsif ( $ref_type =~ m/scalar/i ) {
	  $item = ${$item};
	  ($item, $changed) = $self->replace_configuration_items($item, $other_sections);
	} elsif ( $ref_type =~ m/^array/i ) {
	  my $has_changed = FALSE;
	  for ( my $loop = 0; $loop < scalar(@{$item}); ++$loop ) {
	    ($item->[$loop], $has_changed) = $self->replace_configuration_items($item->[$loop], $other_sections);
	    $changed = TRUE if ( defined($has_changed) && $has_changed eq TRUE );
	  }
	} elsif ( $ref_type =~ m/hash/i ) {
	  my $has_changed = FALSE;
	  my @keys = keys(%{$item});
	  for ( my $loop = 0; $loop < scalar(@keys); ++$loop ) {
	    ($item->{$keys[$loop]}, $has_changed) = $self->replace_configuration_items($item->{$keys[$loop]}, $other_sections);
	    $changed = TRUE if ( defined($has_changed) && $has_changed eq TRUE );
	  }
	}

	return ($item, $changed);
  }

#=============================================================================
1;