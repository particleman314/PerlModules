package HP::Providers::Support;

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

    $VERSION = 0.75;

    @EXPORT  = qw (
                  );

    $module_require_list = {							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Utilities'                => undef,
							'HP::Array::Tools'             => undef,
							'HP::CheckLib'                 => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_providers_support_pm'} ||
				 $ENV{'debug_providers_modules'} ||
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
sub add_version_item
  {
    my $self     = shift;
	my $new_data = shift || return FALSE;
	
	return FALSE if ( &is_type($new_data, 'HP::VersionObject') eq FALSE );
	return FALSE if ( not defined($new_data->get_version()) );
	
	if ( $self->has_version($new_data) eq FALSE ) {
	  $self->version()->push_item($new_data);
	  return TRUE;
	}
	return FALSE;
  }

#=============================================================================
sub convert_output
  {
    my $self     = shift;
	my $specific = { 'mandatory' => { &FORWARD => [ 'bool2string', __PACKAGE__ ], &BACKWARD => [ 'string2bool', __PACKAGE__ ] } };

	$specific    = &HP::Support::Hash::__hash_merge($specific, $self->SUPER::convert_output());
	return $specific;
  }

#=============================================================================
sub data_types
  {
    my $self = shift;
    my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'name'        => undef,
					   'displayName' => undef,
					   'mandatory'   => FALSE,
	                   'version'     => '[] c__HP::VersionObject__',    
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
sub get_version_items
  {
    my $self = shift;
	return $self->version()->get_elements();
  }
  
#=============================================================================
sub get_versions
  {
    my $self  = shift;
	my $items = $self->get_version_items();
	
	my $result = [];
	
	foreach ( @{$items} ) {
	  push ( @{$result}, $_->get_version() ) if ( &is_type($_, 'HP::VersionObject') eq TRUE )
	}
	
	return $result;
  }
  
#=============================================================================
sub has_version
  {
    my $self      = shift;
	my $vID       = shift;
	my $delimiter = shift || $self->get_version_delimiter();
	
	my $result = FALSE;
	
	my $copy_vobj = undef;
	if ( &is_type($vID, 'HP::VersionObject') eq FALSE ) {
	  $copy_vobj = &get_template_obj($self->version())->clone();
	  return $result if ( not defined($copy_vobj) );
	
	  $copy_vobj->set_version_delimiter($delimiter);
	  $copy_vobj->version($vID);
	  $copy_vobj->update();
	} else {
	  $copy_vobj = $vID;  # Shallow copy of VersionObject
	}
	
	foreach ( @{$self->get_version_items()} ) {
	  return TRUE if ( &equal($_->get_version(), $copy_vobj->get_version()) eq TRUE );
	}
	
	return $result;
  }
  
#=============================================================================
sub merge
  {
    my $self     = shift;
	my $new_data = shift;
	
	my $versions = $new_data->get_version_items();
	foreach ( @{$versions} ) {
	  next if ( $self->has_version($_) eq TRUE );
	  $self->add_version_item($_);
	}
	
	return TRUE;
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
	my $vobjs = $self->get_version_items();
	
	foreach ( @{$vobjs} ) {
	  $_->as_attribute();
	}
	
	return;
  }
  
#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	if ( &is_integer($self->mandatory()) eq TRUE ) {
	  $self->mandatory(&convert_boolean_to_string($self->mandatory()));
	}
	return;
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub write_as_attributes
  {
    my $self     = shift;
	my $specific = [ 'name', 'displayName', 'mandatory' ];

	$specific    = &set_union($specific, $self->SUPER::write_as_attributes());
	return $specific;
  }

#=============================================================================
1;