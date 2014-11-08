package HP::CapsuleMetadata::CloudCapsule;

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

	use parent qw(HP::CapsuleMetadata);
	
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
							'HP::Constants'       => undef,
							'HP::Support::Base'   => undef,
							'HP::Support::Hash'   => undef,
							'HP::Support::Object' => undef,
							
							'HP::CheckLib'        => undef,
							'HP::Array::Tools'    => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsulemetadata_cloudcapsule_pm'} ||
				 $ENV{'debug_capsulemetadata_modules'} ||
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
                                        },
                          };
    my %hash = %{$translation_map->{&BACKWARD}};
    my %hsah = reverse %hash;

    $translation_map->{&FORWARD} = \%hsah;
    return $translation_map;
  }

#=============================================================================
sub data_types
  {
    my $self         = shift;
    my $which_fields = shift || COMBINED;
	
    my $data_fields = {
					   'bom'           => 'c__HP::CapsuleMetadata::CloudCapsule::BOM__',
					   'buildinfo'     => 'c__HP::CapsuleMetadata::CloudCapsule::BuildInfo__',
					   'ootb'          => '[] c__HP::CapsuleMetadata::UseCase::Artifact__',
					   'tiertable'     => 'c__HP::CapsuleMetadata::CloudCapsule::TierTable__',
					   'supportMatrix' => 'c__HP::SupportMatrix__',
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
sub force_xml_output
  {
    my $self     = shift;
	my $specific = &get_fields($self);

	$specific    = &set_union($specific, $self->SUPER::force_xml_output());
	return $specific;
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
sub pre_callback_write
  {
    my $self = shift;
	$self->ootb()->{'force_nodename'} = TRUE;
	
	return;
  }

#=============================================================================
sub prepare_xml
  {
    my $self = shift;
	my $rootnode_name = shift || $self->rootnode_name();
	
	return $self->SUPER::prepare_xml($rootnode_name);
  }

#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	
	$self->remove_invalid_entries();
	return;
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub remove_invalid_entries
  {
    my $self = shift;
	
	if ( &is_blessed_obj($self->supportMatrix()) eq TRUE ) {
	  $self->supportMatrix()->remove_invalid_entries() if ( &function_exists($self->supportMatrix(), 'remove_valid_entries') eq TRUE );
	}
	
	return;
  }

#=============================================================================
sub rootnode_name
  {
    my $self = shift;
	return 'capsulePack';
  }
  
#=============================================================================
sub write_xml
  {
    my $self = shift;
	my $filename = shift || &join_path(&getcwd(), 'capsule_pack.manifest');
	
	my $result = $self->SUPER::write_xml("$filename", $self->rootnode_name());
	return $result;
  }

#=============================================================================
1;