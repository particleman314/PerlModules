package HP::Lock::Mutex;

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

	use parent qw(HP::LockObject HP::XML::XMLEnableObject);
	
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

    $VERSION     = 1.2;

    @EXPORT      = qw (
                      );


    $module_require_list = {
							'File::Basename'               => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object::Tools'   => undef,
							
							'HP::Path'                     => undef,
							'HP::FileManager'              => undef,

							'HP::Lock::Constants'          => undef,
							'HP::Stream::Constants'        => undef,
							'HP::Timestamp'                => undef,
							'HP::Os'                       => undef,
							'HP::Support::Os'              => undef,
							'HP::DBContainer'              => undef,
                           };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_lock_mutex_pm'} ||
                 $ENV{'debug_lock_modules'} ||
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
sub __get_lock_data
  {
    my $self = shift;
	my $data = $self->data();
	
    $data->{'timestamp'} = &get_formatted_datetime() if ( not exists($data->{'timestamp'}) );
    $data->{'username'}  = &get_username() if ( not exists($data->{'username'}) );
    $data->{'pid'}       = &get_pid() if ( not exists($data->{'pid'}) );

	$self->data($data);
  }
  
#=============================================================================
sub __prepare_lockfile
  {
    my $self = shift;
	my $filepath = $self->filepath();
	my $dir  = dirname("$filepath");
	my $file = basename("$filepath");
	
	&make_recursive_dirs("$dir") if ( &does_directory_exist("$dir") eq FALSE );
	return FALSE if ( &does_directory_exist("$dir") eq FALSE );	
	return TRUE;
  }
  
#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'filepath' => undef,
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
sub DESTROY
  {
    my $self = shift;

    &__print_debug_output("Calling destructor for object ".ref($self)."\n") if ( $is_debug );
	
	$self->release();
	return;
  }

#=============================================================================
sub display
  {
    my $self   = shift;
	my $handle = shift || 'STDERR';
	
	$self->SUPER::display($handle);
	
	my $strDB  = &getDB('stream');
	my $stream = $strDB->find_stream_by_handle("$handle");
	
	$stream->raw_output("\tFilePath  --> ". $self->filepath()) if ( defined($self->filepath()) );
  }

#=============================================================================
sub lock
  {
    my $self   = shift;
	my $result = FALSE;
	
	$result  = $self->__prepare_lockfile();
	$result  = $self->write_lockdata();
	
	$self->active(TRUE);
	
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
sub prepare_xml
  {
    my $self = shift;
	$self->__get_lock_data();
	return $self->SUPER::prepare_xml($self->rootnode_name());
  }

#=============================================================================
sub release
  {
    my $self = shift;
	$self->unlock();
	$self->SUPER::clear();
	return TRUE;
  }
  
#=============================================================================
sub rootnode_name
  {
    my $self = shift;
	return 'lockfile';
  }
  
#=============================================================================
sub unlock
  {
	my $self = shift;
	my $num_deleted = 0;
	
  	if ( defined($self->filepath()) ) {
	  my $trials = 0;
	  
	TRY_AGAIN:
	  $num_deleted = &delete($self->filepath()) if ( &does_file_exist($self->filepath()) eq TRUE );
	  if ( &does_file_exist($self->filepath()) eq TRUE &&
	       $trials < 3 ) {
	    sleep DELAY;
		++$trials;
		goto TRY_AGAIN;
	  }
	}
	
	if ( $num_deleted == 1 ) {
	  $self->active(FALSE);
	  foreach ( keys(%{$self->data()}) ) {
	    delete($self->{'data'}->{"$_"});
	  }
	  return TRUE;
	}
	return FALSE;
  }

#=============================================================================
sub write_xml
  {
    my $self = shift;
	return $self->SUPER::write_xml($self->filepath(), $self->rootnode_name());
  }
  
#=============================================================================
sub write_lockdata
  {
    my $self = shift;
	return $self->write_xml();
  }

#=============================================================================
1;