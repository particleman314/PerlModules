package HP::Job::Executable;

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

	use overload q{""} => 'HP::Job::Executable::print';
	
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
	                        'File::Basename'             => undef,
							
							'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Hash'          => undef,
							'HP::Support::Object::Tools' => undef,
							'HP::Os'                     => undef,
							'HP::Path'                   => undef,
							'HP::DBContainer'            => undef,
							
							'HP::Array::Tools'           => undef,
							'HP::Job::Constants'         => undef,
							'HP::Utilities'              => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_job_executable_pm'} ||
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
sub data_types
  {
    my $self         = shift;
    my $which_fields = shift || COMBINED;
    my $data_fields  = {
	                    'executable' => undef,
					    'path'       => undef,
					    'valid'      => FALSE,
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
sub get_executable
  {
    my $self   = shift;
	my $result = undef;
	
	if ( $self->valid() eq TRUE ) {
	  my $path = ( defined($self->path()) ) ? $self->path() : '';
	  my $exe  = $self->executable();
	
	  my $driveDB = &getDB('drive');
	  $result = $driveDB->expand_drivepath(&convert_path_to_client_machine(&join_path("$path", "$exe"), &get_os_type()));
	}
	
	return $result;
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
sub print
  {
    my $self        = shift;
	my $indentation = shift || '';
	my $result      = '';
	
	$result .= &print_object_header($self, $indentation) ."\n";

	my $subindent = $indentation . "\t";
	
	$result .= &print_string($self->executable(), 'Executable', $subindent) ."\n";
	$result .= &print_string($self->path(), 'Executable Path', $subindent) ."\n";
	$result .= &print_boolean($self->valid(), 'Validity', undef, $subindent) ."\n";
	
	return $result;
  }
  
#=============================================================================
sub set_executable
  {
    my $self = shift;
	my $exe  = shift || return FALSE;
	
	return FALSE if ( &valid_string($exe) eq FALSE );
	
	$exe = &get_resolved_path("$exe");
	my $dirname  = File::Basename::dirname("$exe");
	my $basename = File::Basename::basename("$exe");

	my $driveDB = &getDB('drive');
	
	# Need to use any drive mapping here...
	my $reduced_path = $driveDB->collapse_drivepath("$dirname");
	
	if ( not defined($reduced_path) ) {
	  $self->path("$dirname");
	} else {
	  $self->path("$reduced_path");
	}
	$self->executable("$basename");
	$self->validate();
	return;
  }

#=============================================================================
sub validate
  {
    my $self = shift;
	
	$self->SUPER::validate();
	
	my $executable = $self->executable();
	my $path       = $self->path();
	
	if ( (( not defined($executable) ) && ( not defined($path) )) ||
	     (( not defined($executable) ) && defined($path)) ) {
	  $self->valid(FALSE);
	  return;
	}
	
	if ( ( defined($executable) && ( not defined($path) )) || 
	     ( defined($executable) && ( defined($path) )) ) {
	  $self->valid(TRUE);
	  return;
	}
	
	#$self->valid(&does_file_exist(&join_path("$path", "$executable")));
	return;
  }

#=============================================================================
1;