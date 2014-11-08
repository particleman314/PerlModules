package HP::SupportMatrix;

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
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							
							'HP::CheckLib'                 => undef,
							'HP::Array::Tools'             => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
				 $ENV{'debug_supportmatrix_pm'} ||
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
                                         'provider' => 'providers',
					                    },
						  };
	my %hash = %{$translation_map->{&BACKWARD}};
	my %hsah = reverse %hash;
	  
	$translation_map->{&FORWARD} = \%hsah;
	return $translation_map;
  }
  
#=============================================================================
sub __merge_provider_details
  {
    my $self     = shift;
	my $result   = FALSE;
	my $old_data = shift || return $result;
	my $new_data = shift || return $result;
	
	$result = $old_data->merge($new_data);
	return $result;
  }

#=============================================================================
sub add_provider
  {
    my $self             = shift;
	my $result           = FALSE;
	my $support_provider = shift || return $result;
	
	return $result if ( &is_type($support_provider, 'HP::Providers::Support') eq FALSE );
	my $matched_provider = $self->find_provider($support_provider);
	
	if ( defined($matched_provider) ) {
	  return $self->__merge_provider_details($matched_provider, $support_provider);
	} else {
	  $self->providers()->push_item($support_provider);
	}
	
	return TRUE;
  }
  
#=============================================================================
sub add_support_matrix
  {
    my $self           = shift;
	my $result         = TRUE;
	my $support_matrix = shift || return $result;
	
	my $known_providers = $support_matrix->get_providers();
	my $added = 0;
	
	foreach ( @{$known_providers} ) {
	  my $data = $self->add_provider($_);
	  ++$added if ( $data eq TRUE );
	  $result = $result & $data;
	}
	
	$self->collect_providers() if ( $added > 0 );
	return ($result, $added) if ( wantarray() );
	return $result;
  }
	
#=============================================================================
sub collect_providers
  {
    my $self = shift;
	my $known_providers = &create_object('c__HP::Array::Set__');
	
	foreach ( @{$self->get_providers()} ) {
	  $known_providers->push_item($_->displayName());
	}
	
	$self->known_providers($known_providers->get_elements());
	return;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
    my $which_fields = shift || COMBINED;
	
    # See if there is a way to read this from file.
    my $data_fields = {
					   known_providers => [],
	                   providers       => '[] c__HP::Providers::Support__',          
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
sub does_software_support_version
  {
    my $self    = shift;
	my $result  = FALSE;
	
	my $swowner = shift || return $result;
	my $version = shift;
	
	return $result if ( not defined($version) );
	if ( &is_type($version, 'HP::VersionObject') eq FALSE ) {
	  my $temp = &create_object('c__HP::VersionObject__');
	  if ( defined($temp) ) {
	    $temp->version($version);
		$temp->update();
		$version = $temp;
	  } else {
	    &__print_output("Unable to create a version object -- possibly insufficient memory...", WARN);
		return $result;
	  }
	}
	
	my $software_grp = $self->get_software_group("$swowner");
	if ( scalar(@{$software_grp}) > 0 ) {
	  foreach ( @{$software_grp} ) {
	    if ( $version->equals($_->version()) eq TRUE ) {
		  $result = TRUE;
		  last;
		}
	  }
	}
	
    return $result;
  }
  
#=============================================================================
sub find_provider
  {
    my $self   = shift;
	my $result = undef;
	
	my $data   = shift || return $result;
	
	if ( &is_type($data, 'HP::Providers::Support') ne TRUE ) {
	  return $result if ( ref($data) !~ m/hash/i );
	  return $result if ( not exists($data->{'lookup'}) );
	  return $result if ( not exists($data->{'value'}) );
	
	  foreach my $i ( @{$self->get_providers()} ) {
	    if ( exists($i->{$data->{'lookup'}}) && defined($i->{$data->{'lookup'}}) ) {
	      return $i if ( $i->{$data->{'lookup'}} eq $data->{'value'} );
	    }
      }
	} else {
	  my $matchdata = ( defined($data->name()) ) ? $data->name() : $data->displayName();
	  
	  foreach my $i ( @{$self->get_providers()} ) {
	    my $match = $self->look_for_provider($matchdata);
		return $match if ( defined($match) );
	  }
	}
	
	return $result;
  }
  
#=============================================================================
sub find_provider_by_displayname
  {
    my $self = shift;
	return $self->find_provider( {'lookup' => 'displayName', 'value' => "$_[0]"} );  
  }

#=============================================================================
sub find_provider_by_name
  {
    my $self = shift;
	return $self->find_provider( {'lookup' => 'name', 'value' => "$_[0]"} );
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
sub get_providers
  {
    my $self = shift;
	return $self->providers()->get_elements();
  }

#=============================================================================
sub get_software_group
  {
    my $self    = shift;
	my $result  = [];
	my $swowner = shift || return $result;
	
	foreach ( @{$self->get_providers()} ) {
	  if ( $_->name() eq "$swowner" ) {
	    push( @{$result}, $_ );
		last;
	  }
	}
	
	return $result;
  }
  
#=============================================================================
sub has_provider
  {
    my $self     = shift;
	my $result   = FALSE;
	my $provider = shift || return $result;
	
	my $match = undef;
	if ( &is_type($provider, 'HP::Providers::Support') eq TRUE ) {
	  $match = $self->look_for_provider($provider->name());
	  if ( not defined($match) ) {
	    $match = $self->look_for_provider($provider->displayName());
	  }	  
	} else {
	  $match = $self->look_for_provider($provider);
	}
	
	return $result if ( not defined($match) );
	return TRUE;
  }
  
#=============================================================================
sub has_version
  {
    my $self      = shift;
	my $provider  = shift || return;
	my $vID       = shift;
	my $delimiter = shift;
	
	my $result = FALSE;
	
	my $provider_obj = $self->look_for_provider($provider);
	return $result if ( not defined($provider_obj) );
	
	$result = $provider_obj->has_version($vID, $delimiter);
	return $result;
  }
	
#=============================================================================
sub look_for_provider
  {
    my $self  = shift;
    my $value = shift || return undef;
	
	my @search_params = qw(name displayname);
	foreach my $sp ( @search_params ) {
	  my $result = undef;
	  my $evalstr = "\$result = \$self->find_provider_by_$sp('$value');";
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
sub number_providers
  {
    my $self = shift;
	return $self->providers()->number_elements();
  }
  
#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	$self->collect_providers();
	return TRUE;
  }

#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub rootnode_name
  {
    my $self = shift;
	return 'supportMatrix';
  }

#=============================================================================
sub skip_fields
  {
    my $self     = shift;
    my $specific = [ 'known_providers' ];

    $specific    = &set_union($specific, $self->SUPER::skip_fields());
    return $specific;
  }

#=============================================================================
#sub write_xml
#  {
#    my $self     = shift;
#	my $filename = shift || &join_path(&getcwd(), 'supportmatrix.xml');
#	
#	my $result = $self->SUPER::write_xml("$filename", 'supportMatrix');
#	return $result;
#  }
  
#=============================================================================
1;