package HP::CapsuleMetadata::CloudCapsule::BOM;

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

    $VERSION = 0.90;

    @EXPORT  = qw (
                  );

    $module_require_list = {							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::CheckLib'                 => undef,
							
							'HP::Array::Constants'         => undef,
							'HP::Array::Tools'             => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsulemetadata_cloudcapsule_bom_pm'} ||
                 $ENV{'debug_capsulemetadata_cloudcapsule_modules'} ||
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
sub add_entry
  {
    my $self   = shift;
	my $result = FALSE;
	
	my $entry  = shift || goto FINISH;
	
	goto FINISH if ( &is_type($entry, 'HP::CapsuleMetadata::CloudCapsule::BOMFile') eq FALSE );
	
	my $current_entries = $self->file();
	
	if ( $current_entries->contains($entry) eq FALSE ) {
	  $result = $self->push_entry($entry);
	  goto FINISH;
	} else {
	  &__print_output("Previous entry exists for requested BOM entry!", WARN);
	}
	
  FINISH:
    return $result;
  }
  
#=============================================================================
sub data_types
  {
    my $self = shift;
    my $which_fields = shift || COMBINED;
	
    # See if there is a way to read this from file.
    my $data_fields = {
					   count => 0,
					   file  => '[] c__HP::CapsuleMetadata::CloudCapsule::BOMFile__',
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
sub find_bom
  {
    my $self   = shift;
	my $result = undef;
	
	my $data   = shift || return $result;
	
	if ( &is_type($data, 'HP::CapsuleMetadata::CloudCapsule::BOMFile') ne TRUE ) {
	  return $result if ( ref($data) !~ m/hash/i );
	  return $result if ( not exists($data->{'lookup'}) );
	  return $result if ( not exists($data->{'value'}) );
	
	  foreach my $i ( @{$self->file()->get_elements()} ) {
	    if ( exists($i->{$data->{'lookup'}}) && defined($i->{$data->{'lookup'}}) ) {
	      return $i if ( &equal($i->{$data->{'lookup'}}, $data->{'value'}) );
	    }
      }
	} else {
	  foreach my $i ( @{$self->file()->get_elements()} ) {
	    my $match = $i->equals($data);
		return $match if ( $match eq TRUE );
	  }
	}
	
	return $result;
  }

#=============================================================================
sub find_bom_by_tag
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_bom( {'lookup' => 'tag', 'value' => "$_[0]"} );  
  }

#=============================================================================
sub find_bom_by_version
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	
	my $data = $_[0];
	
	if ( &is_type($data, 'HP::VersionObject') eq FALSE ) {
	  my $temp = $data;
	  $data = &create_object('c__HP::VersionObject__');
	  $data->set_version_delimiter($_[1]) if ( defined($_[1]) );
	  $data->set_version($temp);
	}
	return $self->find_bom( {'lookup' => 'version', 'value' => $data} );  
  }

#=============================================================================
sub find_bom_by_md5sum
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_bom( {'lookup' => 'md5sum', 'value' => "$_[0]"} );  
  }

#=============================================================================
sub find_bom_by_name
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_bom( {'lookup' => 'name', 'value' => "$_[0]"} );
  }

#=============================================================================
sub find_entry
  {
    my $self   = shift;
	my $result = undef;
	
	my $entry  = shift || goto FINISH;
  
	my $current_entries = $self->file();
    if ( $self->has_entry($entry) eq TRUE ) {
	  $result = $current_entries->find_instance($entry);
	}
	
  FINISH:
    return $result;
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
sub get_entry
  {
    my $self = shift;
	my $idx  = shift;
	
	return undef if ( not defined($idx) );
	
	my $number_entries = $self->count();
	return undef if ( $idx < 0 || $idx >= $number_entries );
	return $self->file()->get_element($idx);
  }
  
#=============================================================================
sub has_entry
  {
    my $self   = shift;
	my $result = FALSE;
	
	my $entry  = shift || goto FINISH;

	my $current_entries = $self->file();
	$result = $current_entries->contains($entry);
	
  FINISH:
    return $result;
  }
  
#=============================================================================
sub look_for_bom
  {
    my $self  = shift;
    my $value = shift || return undef;
	
	my @search_params = qw(name md5sum version tag);
	foreach my $sp ( @search_params ) {
	  my $result = undef;
	  my $evalstr = "\$result = \$self->find_bom_by_$sp('$value');";
	  eval "$evalstr";
	  return $result if ( defined($result) );
	}
	
	return undef;
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
sub push_entry
  {
    my $self = shift;
	my $entry = shift || return FALSE;
	
	$self->file()->push_item($entry);
	$self->count($self->file()->number_elements());
	return TRUE;
  }
  
#=============================================================================
sub remove_entry
  {
    my $self   = shift;
	my $result = FALSE;

	my $entry  = shift || goto FINISH;
  
	my $current_entries = $self->file();
    if ( $self->has_entry($entry) eq TRUE ) {
	  my $idx = $current_entries->find_instance($entry);
	  my $success = $current_entries->delete_elements_by_index($idx);
	  $self->count($current_entries->number_elements()) if ( $success eq TRUE );
	  $result = $success;
	}
	
  FINISH:
    return $result;
  }
  
#=============================================================================
sub write_as_attributes
  {
    my $self     = shift;
	my $specific = [ 'count' ];

	$specific    = &set_union($specific, $self->SUPER::write_as_attributes());
	return $specific;
  }

#=============================================================================
1;