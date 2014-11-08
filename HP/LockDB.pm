package HP::LockDB;

################################################################################
# Copyright (c) 2013 HP.   All rights reserved
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

use warnings;
use strict;
use diagnostics;

#=============================================================================
BEGIN
  {
    use Exporter();

    use FindBin;
    use lib "$FindBin::Bin/..";

	use parent qw(HP::DB);
	
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

    $VERSION = 1.2;

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
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_lockdb_pm'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
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
sub _new_instance
  {
    return &new(@_);
  }
  
#=============================================================================
sub add_lock
  {
    my $self   = shift;
	my $result = FALSE;
	my $lock   = shift || return $result;
	
	return $result if ( &is_type($lock, 'HP::LockObject') eq FALSE );
	my $key = $lock->get_key();
	
	my $match = $self->find_lock($key);
	
	if ( not defined($match) ) {
	  $self->known_locks()->push_item($lock);
	} else {
	  if ( &is_type($match, 'HP::Mutex') eq TRUE ) {
	    my $semaphore = $self->upgrade_to_semaphore($match);
		if ( defined($semaphore) ) {
		  $match = $semaphore;
		} else {
		  &__print_output("Unable to upgrade MUTEX to SEMAPHORE lock!", WARN);
		}
	  }
	}
  }

#=============================================================================
sub clear
  {
    my $self = shift;
	
	$self->clear_locks();
	return;
  }
  
#=============================================================================
sub clear_locks
  {
    my $self = shift;
	
	foreach ( @{$self->known_locks()->get_elements()} ) {
	  $_->release();
	}
	$self->known_locks()->clear();
	return;
  }
  
#=============================================================================
sub data_types
  {
    my $data_fields = {
					   'known_locks' => 'c__HP::Array::Set__',
					   'valid'       => FALSE,
		              };
    
    foreach ( @ISA ) {
	  my $parent_types = undef;
	  if ( &function_exists($_, 'data_types') eq TRUE ) {
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
    return $data_fields;
  }

#=============================================================================
sub DESTROY
  {
    my $self = shift;

    &__print_debug_output("Calling destructor for object ".ref($self)."\n") if ( $is_debug );
	
	if ( &is_type($self->{'known_locks'}, 'HP::Array::Set') eq TRUE ) {
	  my $locks = $self->{'known_locks'}->get_elements();
	  foreach ( @{$locks} ) {
	    $_->release();
	  }
    }
	
	return;
  }

#=============================================================================
sub find_lock
  {
    my $self = shift;
	my $key  = shift || return undef;
	
	foreach ( @{$self->known_locks()->get_elements()} ) {
	  return $_ if ( &equal($_->get_key(), $key) eq TRUE );
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
	$self->valid(TRUE);
	return $self;  
  }

#=============================================================================
sub remove_lock
  {
    my $self   = shift;
	my $result = FALSE;
	my $key    = shift || return $result;
	
	my $lock = $self->find_lock($key);
	return $result if ( not defined($lock) );
	
	my $index = $self->known_locks()->find_instance($lock);
	$lock->release();
	$self->delete_elements_by_index($index);
	return TRUE;
  }

#=============================================================================
sub show_locks
  {
    my $self = shift;
	
	foreach ( @{$self->known_locks()->get_elements()} ) {
	  $_->display();
	}
	return;
  }
  
#=============================================================================
sub upgrade_to_semaphore
  {
    my $self = shift;
	my $lock = shift || return undef;
	
	return $lock if ( &is_type($lock, 'HP::Semaphore') eq TRUE );
	my $semaphore = &create_object('c__HP::Semaphore__');
	return undef if ( not defined($semaphore) );
	
	$semaphore->refcount(1);
	
	my $fields = &get_fields($lock, TRUE);
	foreach ( @{$fields} ) {
	  $semaphore->{"$_"} = $lock->{"$_"};  # Shallow copy to keep all references...
    }	
	return $semaphore;
  }
  
#=============================================================================
1;