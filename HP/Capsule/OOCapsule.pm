package HP::Capsule::OOCapsule;

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

	use parent qw(HP::Capsule::Common);
	
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
							'HP::Support::Configuration'   => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::CheckLib'                 => undef,
							
							'HP::CSL::Tools'               => undef,
							'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsule_oocapsule_pm'} ||
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
sub convert_usecase_capsule
  {
    my $self   = shift;
	my $uc_obj = shift || return;
	
	return FALSE if ( &is_type($uc_obj, 'HP::Capsule::UseCaseCapsule') eq FALSE );
	return FALSE if ( not defined($uc_obj->{'usecase'}) );
		
	$self->name($uc_obj->name());
	$self->usecase($uc_obj->usecase());

    $self->shared_flow_dir($uc_obj->shared_flow_dir());	
	$self->allow_2_build(TRUE);
	$self->local_data($uc_obj->local_data());
	$self->parameters($uc_obj->parameters());
	$self->version($uc_obj->version());
	$self->get_parameters()->{'version'} = $self->version()->get_version();  # TODO : Fix this to not remove version from parameter section
	
	return TRUE;
  }
  
#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
					   'allow_2_build'  => FALSE,
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
sub get_type
  {
    my $self = shift;
	return 'oo';
  }

#=============================================================================
sub load_local_xmldata
  {
    my $self = shift;
	my $buildpath = shift;
	
	my $path = $self->SUPER::load_local_xmldata("$buildpath", 'name');
	$self->oocase_dir("$path");
	return;
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
		  if ( exists($self->{"$key"}) ) {
		    $self->{"$key"} = $_[0]->{"$key"};
		  }
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
sub post_callback_read
  {
    my $self = shift;
	
	$self->version()->set_version(${$self->get_parameters()->{'version'}});
	delete($self->get_parameters()->{'version'});
	
	my $gds = &get_global_datastore();
	if ( defined($gds) ) {
	  my $provider = $gds->get_matching_provider($self->name());
	  if ( &is_type($provider, 'HP::ArrayObject') eq TRUE ) {
	    &__print_output("Unable to discern proper OO capsule name due to ambiguity!", FAILURE);
		return FALSE;
	  }
	  
	  if ( defined($provider) ) {
	    $self->name($provider->name());
	    $self->usecase($provider->usecase());
	  } else {
	    return FALSE;
	  }
	}
	return TRUE;
  }
  
#=============================================================================
sub validate
  {
    my $self = shift;
	
	return FALSE if ( not defined($self->get_parameters()->{'name'}) );
	
	$self->get_parameters()->{'level'} = 1 if ( $self->get_parameters()->{'level'} < 0 );
	return TRUE;
  }
  
#=============================================================================
1;