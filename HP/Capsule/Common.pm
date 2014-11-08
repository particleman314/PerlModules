package HP::Capsule::Common;

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

    $VERSION = 1.00;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Hash'          => undef,
							'HP::Support::Object::Tools' => undef,
							'HP::Support::Configuration' => undef,
							'HP::CheckLib'               => undef,
							
							'HP::Capsule::Constants'     => undef,
							'HP::CSL::Tools'             => undef,
							'HP::Path'                   => undef,
							'HP::FileManager'            => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsule_common_pm'} ||
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
sub data_types
  {
    my $self        = shift;
	my $which_level = shift || COMBINED;
	
    my $data_fields = {
					   'version'    => 'c__HP::VersionObject__',
					   'parameters' => 'c__HP::CSL::DAO::Section__',
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
sub get_type
  {
    my $self = shift;
	return undef;
  }
  
#=============================================================================
sub get_version
  {
    my $self = shift;
	return $self->version()->get_version();
  }
  
#=============================================================================
sub get_parameters
  {
    my $self = shift;
	return $self->parameters()->configuration();
  }

#=============================================================================
sub load_local_xmldata
  {
    my $self      = shift;
	my $buildpath = shift;
	my $selector  = shift;
	
	return FALSE if ( &valid_string($selector) eq FALSE );

	my $selection = $self->{"$selector"};
	return FALSE if ( not defined($selection) );
	
	my $gds = &get_global_datastore();
	return undef if ( not defined($gds) );
	
	my $name = $gds->get_normalized_provider_name("$selection");
	
	return undef if ( (not defined($name)) || ref($name) =~ m/^array/i );
	my $capsule = $gds->get_matching_provider("$name");
	
	if ( defined($capsule) ) {
	  my $usecase = $capsule->usecase();
	  my $path    = &join_path("$buildpath", "$usecase");
	  
	  $self->{'shared_flow_dir'} = &get_resolved_path(&join_path("$buildpath",$capsule->workflow())) if ( defined($capsule->workflow()) );

	  my $already_loaded = FALSE;
	  my $lds = &get_local_datastore();
	  if ( defined($lds) ) {
	    # Here we have somewhere already possibly loaded the story in question...
	    if ( exists($lds->{'stories'}->{"$name"}) ) {
		  $self->{'local_data'} = $lds->{'stories'}->{"$name"};
		  $already_loaded = TRUE;
		}
	  }
	  if ( $already_loaded eq FALSE ) {
		my $ldo = &create_object('c__HP::CSL::DAO::LocalData__');
		if ( defined($ldo) ) {
	      my $xmlfile = &path_to_unix(&join_path("$path", LOCAL_SS_FILE));
	      $ldo->readfile("$xmlfile") if ( &does_file_exist("$xmlfile") eq TRUE );
		  &save_to_configuration({'data' => [ "derived_data->local->stories->$name", $ldo ]});
		  $self->{'local_data'} = \$ldo;  # We keep a reference to it here is it was newly loaded
		}
	  }
	  return &get_resolved_path("$path");
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
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub set_version
  {
    my $self = shift;
	my $vID  = shift || return FALSE;
	
	my $version_delimiter = shift || $self->version()->get_version_delimiter();
	
	if ( &is_type($vID, 'HP::VersionObject') eq TRUE ) {
	  $self->version($vID);
	} else {
	  $self->version()->set_version_delimiter($version_delimiter);
	  $self->version()->set_version($vID);
	}
	
	return TRUE;
  }

#=============================================================================
1;