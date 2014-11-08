package HP::InodeEntry;

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

    $VERSION = 0.9;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'             => undef,
							'HP::Support::Base'         => undef,
							'HP::Support::Hash'         => undef,
							'HP::Support::Os'           => undef,
	                        'HP::CheckLib'              => undef,
							
							'HP::InodeEntry::Constants' => undef,
							'HP::FileManager'           => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_inodeentry_pm'} ||
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
sub check_existence
  {
    my $self = shift;
	
	my $path = $self->path();
	
	if ( not defined($path) ) {
	  $self->exists(FALSE);
	  $self->clear_type();
	  goto COMPLETE;
	}
	
	if ( &os_is_windows() eq FALSE ) {
	  $self->exists(TRUE);
	  if ( -l "$path" ) {
		$self->type()->{&LINK} = TRUE;
      }
	  goto COMPLETE;
	}
	
	if ( &does_file_exist("$path") eq TRUE ) {
	  $self->exists(TRUE);
	  $self->type()->{&FILE} = TRUE;
	  goto COMPLETE;
	}
	
	if ( &does_directory_exist("$path") ) {
	  $self->exists(TRUE);
	  $self->type()->{&DIRECTORY} = TRUE;
	  goto COMPLETE;
	}
	
  COMPLETE:
	if ( ( $self->exists() eq TRUE ) ) {
	  if ( $self->identity() eq FALSE ) {
	    $self->type()->{&OTHER_NODE} = TRUE;
	  }
	}

	$self->validate();
	return;
  }
  
#=============================================================================
sub clear
  {
    my $self = shift;
	
	$self->clear_type();
	$self->SUPER::clear();
  }
  
#=============================================================================
sub clear_type
  {
    my $self = shift;
	my @types = keys (%{$self->type()});
	
	foreach ( @types ) {
      $self->{'type'}->{$_} = FALSE;
	}
  }

#=============================================================================
sub convert_output
  {
    my $self     = shift;
	my $specific = { 'valid'  => { &FORWARD => [ 'bool2string', __PACKAGE__ ], &BACKWARD => [ 'string2bool', __PACKAGE__ ] },
                     'exists' => { &FORWARD => [ 'bool2string', __PACKAGE__ ], &BACKWARD => [ 'string2bool', __PACKAGE__ ] } };
	
	$specific = &HP::Support::Hash::__hash_merge($specific, $self->SUPER::convert_output());
	return $specific;
  }

#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    # See if there is a way to read this from file.
    my $data_fields = {
					   'path'     => undef,
					   'exists'   => FALSE,
					   'type'     => {
					                  &FILE       => FALSE,
									  &DIRECTORY  => FALSE,
									  &LINK       => FALSE,
									  &OTHER_NODE => FALSE,
								     },
					   'valid'    => FALSE,
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
sub identity
  {
    my $self = shift;
	my @types = keys (%{$self->type()});
	
	foreach ( @types ) {
	  return TRUE if ( $self->{'type'}->{$_} eq TRUE );
	}
	
	return FALSE;
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
	$self->{'__firsttime'} = TRUE;
	if ( @_ ) {
	  $self->rescan();
	  delete($self->{'__firsttime'});
	}
    return $self;
  }

#=============================================================================
sub print
  {
    my $self = shift;
	
	$self->SUPER::print();
	return;
  }

#=============================================================================  
sub rescan
  {
    my $self = shift;
	
	if ( exists($self->{'__firsttime'}) ) {
      delete($self->{'__firsttime'});
	  $self->valid( TRUE );
    } else {
	  $self->check_existence();
	}
	
	return;
  }
  
#=============================================================================  
sub set_path
  {
    my $self = shift;
	my $path = shift;

	return if ( &valid_string($path) eq FALSE );

	$self->path("$path");
	$self->check_existence();
	return;
  }

#=============================================================================
sub validate
  {
    my $self = shift;
	
	$self->SUPER::validate();
	if ( (defined($self->path())) &&
	     ($self->exists() eq TRUE) ) {
	  $self->valid(TRUE);
	} else {
	  $self->valid(FALSE);
	}
	return;
  }

#=============================================================================
1;