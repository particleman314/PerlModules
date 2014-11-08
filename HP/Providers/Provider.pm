package HP::Providers::Provider;

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
							'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							
							'HP::Support::Hash'          => undef,
							'HP::Support::Object'        => undef,
							'HP::Support::Object::Tools' => undef,
							
	                        'HP::CheckLib'               => undef,
							'HP::Array::Tools'           => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_providers_provider_pm'} ||
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
use constant DEAD_PROVIDER_RECORD => 'NULL';

#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_level = shift || COMBINED;
	
    my $data_fields = {
	                   'hptype'       => undef,
					   'providers'    => '[] c__HP::Providers::Common__ 1',
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
sub find_provider
  {
    my $self   = shift;
	my $result = &create_object('c__HP::Array::Set__');
	
	my $data   = shift || return $result;
	
	return $result if ( ref($data) !~ m/hash/i );
	return $result if ( not exists($data->{'lookup'}) );
	return $result if ( not exists($data->{'value'}) );
	
	foreach ( @{$self->providers()->get_elements()} ) {
	  if ( exists($_->{$data->{'lookup'}}) && defined($_->{$data->{'lookup'}}) ) {
	     $result->push_item($_) if ( &equal($_->{$data->{'lookup'}}, $data->{'value'}) );
	  }
	}
		
	return $result;
  }

#=============================================================================
sub find_provider_by_value
  {
    my $self = shift;
	return $self->find_provider_by_jarfile(@_);
  }
  
#=============================================================================
sub find_provider_by_jarfile
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_provider( {'lookup' => 'value', 'value' => "$_[0]"} );  
  }

#=============================================================================
sub find_provider_by_name
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_provider( {'lookup' => 'name', 'value' => "$_[0]"} );
  }

#=============================================================================
sub find_provider_by_nickname
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_provider( {'lookup' => 'nickname', 'value' => "$_[0]"} );
  }

#=============================================================================
sub find_provider_by_usecase
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_provider( {'lookup' => 'usecase', 'value' => "$_[0]"} );  
  }

#=============================================================================
sub find_provider_by_workflow
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_provider( {'lookup' => 'workflow', 'value' => "$_[0]"} );  
  }

#=============================================================================
sub find_provider_by_sdpattern
  {
    my $self = shift;
	return undef if ( not defined($_[0]) );
	return $self->find_provider( {'lookup' => 'sdpattern', 'value' => "$_[0]"} );  
  }

#=============================================================================
sub get_provider_type
  {
    my $self = shift;
	return $self->hptype();
  }
  
#=============================================================================
sub look_for_provider
  {
    my $self  = shift;
    my $value = shift || return undef;
	
	my $param = undef;
	if ( ref($value) =~ m/hash/i ) {
	  $param = $value->{'lookup'};
	  $value = $value->{'value'};
	}
	
	my $search_params = [ 'name', 'nickname', 'usecase', 'value', 'workflow', 'sdpattern' ];
	$search_params = &set_intersect($param, $search_params) if ( defined($param) );
	
	my $collection = &create_object('c__HP::Array::Set__');
	
	foreach my $sp ( @{$search_params} ) {
	  my $result = undef;
	  my $evalstr = "\$result = \$self->find_provider_by_$sp('$value');";
	  eval "$evalstr";
	  $collection->merge($result) if ( defined($result) &&
	                                   &is_type($result, 'HP::ArrayObject') eq TRUE &&
									   $result->is_empty() eq FALSE );
	}
	
	return $collection;
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
sub read_xml
  {
	my $result   = FALSE;
    my $self     = shift;
	my $node     = shift || return $result;
	my $type     = shift || $self->hptype();
	
	return $result if ( not defined($type) );
	
	my $rootpath = "//$type/providers";
	
	$self->pre_callback_read() if ( &function_exists($self, 'pre_callback_read') eq TRUE );
	
	$result = &HP::XML::Utilities::__read_xml($self, $node, $rootpath);
	
	$self->post_callback_read() if ( &function_exists($self, 'post_callback_read') eq TRUE );
	
	$self->validate();
	return $result;
  }
  
#=============================================================================
sub remove_duplicates
  {
    my $self = shift;
	
	my $providers = $self->providers()->get_elements();

	for ( my $outloop = 0; $outloop < scalar(@{$providers}); ++$outloop ) {
	  for ( my $inloop = $outloop + 1; $inloop < scalar(@{$providers}); ++$inloop ) {
	    next if ( $providers->[$inloop] eq DEAD_PROVIDER_RECORD );
	    if ( &equal($providers->[$outloop], $providers->[$inloop]) eq TRUE ) {
		  $providers->[$inloop] = DEAD_PROVIDER_RECORD;
		}
	  }
	}

	return;
  }
  
#=============================================================================
sub remove_invalid_entries
  {
    my $self = shift;
	
	my $providers = $self->providers()->get_elements();
	
	if ( defined($providers) ) {
	  for ( my $loop = 0; $loop < scalar(@{$providers}); ++$loop ) {
	    if ( $providers->[$loop]->valid() eq FALSE ) {
		  $providers->[$loop] = DEAD_PROVIDER_RECORD;
		}
	  }
	}
	
	$self->remove_duplicates();
	$self->providers()->delete_elements(DEAD_PROVIDER_RECORD);
	return;
  }

#=============================================================================
sub write_xml
  {
    my $self = shift;
	my $type = shift || $self->type();
	
	#TODO
	return;
  }
  
#=============================================================================
1;