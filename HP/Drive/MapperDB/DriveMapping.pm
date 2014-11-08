package HP::Drive::MapperDB::DriveMapping;

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
				$comment
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
							'HP::Support::Os'              => undef,
	                        'HP::CheckLib'                 => undef,

							'HP::Path'                     => undef,
							'HP::Path::Constants'          => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_drive_mapperdb_drivemapping_pm'} ||
				 $ENV{'debug_drive_mapperdb_modules'} ||
				 $ENV{'debug_drive_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;
	$comment        = '#';
	
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
sub add_pid
  {
    my $self = shift;
	my $pid  = shift || return FALSE;
	
	my $pidlist = $self->pidlist();
	if ( $pidlist->contains($pid) eq FALSE ) {
	  $pidlist->push($pid);
	} else {
	  &__print_debug_output("PID << $pid >> already exists in list") if ( $is_debug );
	}
	return TRUE;
  }

#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
					   'fullpath'     => undef,
					   'reduced_path' => undef,
					   'pidlist'      => 'c__HP::Array::QueueSet__',
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
sub get_pids
  {
    my $self = shift;
	return $self->pidlist()->get_elements();
  }
  
#=============================================================================
sub has_pid
  {
    my $self = shift;
	my $pid  = shift || return FALSE;
	
	return $self->pidlist()->contains($pid);
  }
  
#=============================================================================
sub is_free
  {
    my $self = shift;
	return $self->pidlist()->is_empty();
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
		  $self->{"$key"} = $_[0]->{"$key"} if ( exists($self->{"$key"}) );
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class < $class >", 'STDERR');
		return undef;
	  }
	}

    bless $self, $class;
	$self->instantiate();
    return $self;
  }

#=============================================================================
sub remove_pid
  {
    my $self = shift;
	my $pid  = shift || return FALSE;
	
	my $pidlist = $self->pidlist();
	if ( $pidlist->contains($pid) eq TRUE ) {
	  $pidlist->delete_elements($pid);
	} else {
	  &__print_debug_output("PID << $pid >> does NOT exist in list") if ( $is_debug );
	}
	return TRUE;
  }
  
#=============================================================================
sub request_reduced_path
  {
    my $self = shift;
	my $path = shift;
	return undef if ( &valid_string($path) eq FALSE );
	
	my ($common_root, $uncommon_parts) = &path_find_common_root("$path", $self->fullpath());
	my $newpath = $path;
	
	if ( $common_root eq $self->fullpath() ) {
	  if ( scalar(@{$uncommon_parts}) > 0 ) {
	    $newpath = &join_path($self->reduced_path(), @{$uncommon_parts});
	  } else {
	    $newpath = $self->reduced_path();
	  }
	} else {
	  $newpath = $self->fullpath() . '/' . &find_relative_path($self->fullpath(), "$path");
	  $newpath = &HP::Path::__flip_slashes("$newpath", PATH_FORWARD, PATH_BACKWARD) if ( &os_is_windows() eq TRUE );
	  $newpath = $self->request_reduced_path("$newpath");
	}
	
	return "$newpath";
  }
  
#=============================================================================
1;