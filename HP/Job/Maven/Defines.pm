package HP::Job::Maven::Defines;

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

	use parent qw(HP::BaseObject);
	
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
	                        'HP::Constants'        => undef,
							'HP::Support::Base'    => undef,
							'HP::Support::Hash'    => undef,
							'HP::Support::Module'  => undef,
							'HP::Support::Object'  => undef,
							'HP::CheckLib'         => undef,

							'HP::Array::Tools'     => undef,
							'HP::Array::Constants' => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_job_maven_defines_pm'} ||
				 $ENV{'debug_job_maven_modules'} ||
				 $ENV{'debug_job_modules'} ||
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
sub add_defines
  {
    my $self = shift;
	my $item = shift;
	
	my $ref_type = ref($item);
	return if ( $ref_type !~ '' || $ref_type !~ m/^scalar/i );

	$self->defines()->push_item($item) if ( $ref_type eq '' );
	$self->defines()->push_item(${$item}) if ( $ref_type =~ m/^scalar/i );
	
	return;
  }
  
#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'defines' => 'c__HP::Array::Set__',
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

	$specific = &set_union($specific, $self->SUPER::force_xml_output());
	return $specific;
  }

#=============================================================================
sub get_define
  {
    my $self = shift;
	my $key  = shift || return undef;
	
	my $idx = $self->defines()->find_instance($key);
	return undef if ( $idx eq NOT_FOUND );
	return $self->defines()->get_element($idx);
  }
  
#=============================================================================
sub has_define
  {
    my $self = shift;
	my $key  = shift || return FALSE;
	
	return FALSE if ( $self->defines()->find_instance($key) eq NOT_FOUND );
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
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub remove_defines
  {
    my $self = shift;
	my $key  = shift;
	
	return FALSE if ( &valid_string($key) eq FALSE );
	return FALSE if ( $self->has_define("$key") eq FALSE );
	return $self->defines()->delete_elements("$key");
  }
  
#=============================================================================
sub write_as_attributes
  {
    my $self = shift;
	
	my $specific = [];

	$specific = &set_union($specific, $self->SUPER::write_as_attributes());
	return $specific;
  }

#=============================================================================
1;