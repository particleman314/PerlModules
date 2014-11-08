package HP::StreamDB;

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

    $VERSION = 0.75;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'File::Basename'               => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
	                        'HP::CheckLib'                 => undef,
							
							'HP::Stream::Constants'        => undef,
							'HP::Array::Constants'         => undef,
							
							'HP::StreamDB::Constants'      => undef,
							'HP::FileManager'              => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_streamdb_pm'} ||
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
sub __install_system_stream
  {
    my $self = shift;
	my $data = shift || return;
	
	my $obj = &create_object('c__HP::Stream::IO__');
	if ( defined($obj) ) {
	  $obj->set_system(TRUE);
	  $obj->fileglob($data->{'FILEGLOB'});
	  $obj->active($data->{'ACTIVE'});
	  $obj->valid(TRUE);
	  
	  $self->add_system_stream($data->{'HANDLE'}, $obj);
	}
	
	return;
  }
  
#=============================================================================
sub _new_instance
  {
    return &new(@_);
  }
  
#=============================================================================
sub __shutdown_system_stream
  {
    my $self = shift;
	my $known_streams = $self->known_handles();
	my @handles = keys(%{$known_streams});

	foreach ( @handles ) {
	  next if ( $known_streams->{$_}->is_system() eq FALSE );
      delete($known_streams->{$_});
    }	
  }
  
#=============================================================================
sub __work_with_stream
  {
    my $self = shift;
	my $known_methods = [ 'COPY', 'MOVE' ];
	my ($old_handle, $new_handle, $method) = @_;

	$method = $known_methods->[0] if ( &valid_string($method) eq FALSE );
	my $arrobj = &create_object('c__HP::Array::Set__');
	if ( defined($arrobj) ) {
	  $arrobj->add_elements( {'entries' => $known_methods} );
	} else {
	  return FALSE;
	}
	return FALSE if ( $arrobj->contains($method) eq FALSE );
	
	return FALSE if ( ( &valid_string($old_handle) eq FALSE ) || ( &valid_string($new_handle) eq FALSE ) );
	return FALSE if ( $self->has_handle($old_handle) eq FALSE );
	
	if ( $self->has_handle($new_handle) eq TRUE ) {
	  return FALSE if ( $self->remove_stream($new_handle) eq FALSE );
	}
	
	my $known_streams  = $self->known_handles();
	my $old_handle_obj = $known_streams->{$old_handle};
	my $new_handle_obj = $old_handle_obj->clone();	  

	return FALSE if ( not defined($new_handle_obj) );

	my $result = $new_handle_obj->equals($old_handle_obj);
	if ( $result eq TRUE ) {
      $known_streams->{$new_handle} = $new_handle_obj;
	  delete($known_streams->{$old_handle}) if ( $method eq MOVE );
	  return TRUE;
	}
	return FALSE;
  }
  
#=============================================================================
sub add_system_stream
  {
    my $self    = shift;
	
	my $handle       = shift || return FALSE;
	my $sysstreamobj = shift || return FALSE;
	
	return FALSE if ( &is_type($sysstreamobj, 'HP::Stream') eq FALSE );
	$sysstreamobj->set_system();
	
	$self->{'known_handles'}->{$handle} = $sysstreamobj;
	return TRUE;
  }

#=============================================================================
sub add_stream
  {
    my $self    = shift;
	
	my $handle    = shift || return FALSE;
    my $streamobj = shift || return FALSE;  
	
	return FALSE if ( ( &valid_string($handle) eq FALSE ) ||
	                  ( &is_type($streamobj, 'HP::Stream') eq FALSE ) );
	
	if ( $self->has_handle($handle) eq TRUE ) {
	  my $path = $streamobj->get_path();
	  if ( defined($path) ) {
	    &__print_output("Found previously defined path << ". $streamobj->get_path() ." >> assigned to another handle", WARN);
	  } else {
	    &__print_output("Found previously defined handle << $handle >>", WARN);
	  }
	  return FALSE;
	}
	
	$self->{'known_handles'}->{$handle} = $streamobj;
	return TRUE;
  }
  
#=============================================================================
sub clear
  {
    my $self = shift;
	
	# Be sure to NOT close/remove any SYSTEM handles
	
	if ( exists($self->{'known_handles'}) ) {
	  my $known_streams = $self->{'known_handles'};
	  my @handles = sort keys(%{$known_streams});
	
	  foreach ( @handles ) {
	    my $streamobj = $known_streams->{$_};
	    next if ( (not defined($streamobj)) || $streamobj->is_system() );
	    $self->remove_stream($_);
	  }
	}
	
	$self->{'valid'} = FALSE if ( exists($self->{'valid'}) );
	return;
  }

#=============================================================================
sub copy_stream
  {
    my $self = shift;
    return $self->__work_with_stream(@_, COPY);
  }
  
#=============================================================================
sub data_types
  {
    my $data_fields = {
					   'known_handles' => {},
					   'valid'         => FALSE,
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
	$self->clear();
	return;
  }

#=============================================================================
sub find_inode_entry_by_handle
  {
    my $self   = shift;
	my $handle = shift;
	
	return undef if ( &valid_string($handle) eq FALSE );
	return undef if ( $self->has_handle($handle) eq FALSE );
	
	my $stream_obj = $self->find_stream_by_handle($handle);
    return $stream_obj->entry();
  }

#=============================================================================
sub find_stream_by_path
  {
    my $self = shift;
	my $path = shift || return undef;
	
	return undef if ( &valid_string($path) eq FALSE );
	
	my $known_streams = $self->known_handles();
	foreach ( keys(%{$known_streams}) ) {
      next if ( &is_type($known_streams->{$_}, 'HP::Stream') eq FALSE );
	  next if ( $known_streams->{$_}->is_system() );
	  return $known_streams->{$_} if ( ( defined($known_streams->{$_}->get_path()) ) &&
                                       ( $known_streams->{$_}->get_path()	eq "$path" ) );
	}
	return undef;
  }

#=============================================================================
sub find_stream_by_handle
  {
    my $self   = shift;
	my $handle = shift;
	
	return undef if ( &valid_string($handle) eq FALSE );
	
	return undef if ( $self->has_handle($handle) eq FALSE );
	return $self->known_handles()->{$handle};
  }
  
#=============================================================================
sub has_handle
  {
    my $self   = shift;
	my $handle = shift;
	
	return FALSE if ( &valid_string($handle) eq FALSE );
	
	my $known_streams = $self->known_handles();
	return FALSE if ( not exists($known_streams->{$handle}) );
	return TRUE;
  }

#=============================================================================
sub install_system_streams
  {
    my $self = shift;
	
	if ( $self->has_handle('STDIN') eq FALSE ) {
	  $self->__install_system_stream( {
	                                   'HANDLE'   => 'STDIN',
					                   'ACTIVE'   => TRUE,
									   'FILEGLOB' => \*STDIN,
									  } );													   
	}
	
	if ( $self->has_handle('STDOUT') eq FALSE ) {
	  $self->__install_system_stream( {
	                                   'HANDLE'   => 'STDOUT',
					                   'ACTIVE'   => TRUE,
									   'FILEGLOB' => \*STDOUT,
									  } );													   
	}

	if ( $self->has_handle('STDERR') eq FALSE ) {
	  $self->__install_system_stream( {
	                                   'HANDLE'   => 'STDERR',
					                   'ACTIVE'   => TRUE,
									   'FILEGLOB' => \*STDERR,
									  } );													   
	}
	
	return;
  }

#=============================================================================
sub make_stream
  {
    my $self     = shift;
	my $filename = shift;
	my $str_type = shift || OUTPUT;
	my $handle   = shift || '__GENERATED0__';
	
	return undef if ( &valid_string($filename) eq FALSE );
	
	my $previous_stream = &find_stream_by_handle($handle);
	return $previous_stream if ( defined($previous_stream) );
	
	my $new_stream = &create_object('c__HP::Stream::IO::'. $str_type .'__');
	
	# Need a method to uniquify the handle!!!
	
	if ( defined($new_stream) ) {
	  $new_stream->handle($handle);
      $new_stream->entry()->set_path($filename);
	  $new_stream->open();
	  $self->add_stream($handle, $new_stream);
	}
	
	return $new_stream;
  }
  
#=============================================================================
sub move_stream
  {
    my $self = shift;
    return $self->__work_with_stream(@_, MOVE);
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
	$self->validate();
	$self->install_system_streams();
    return $self;
  }

#=============================================================================
sub number_streams
  {
    my $self = shift;
	my $attr = shift || undef;
	
	my $total = 0;
	
	my $known_streams = $self->known_handles();
	my @handles = keys(%{$known_streams});
	
	if ( defined($attr) ) {
	  if ( &function_exists($self, "is_$attr") eq TRUE ) {
		foreach ( @handles ) {
		  my $result   = FALSE;
	      my $evalstr  = "\$result = \$_->is_$attr()";
	      eval "$evalstr";
		  ++$total if ( $result eq TRUE );
	    }
	  }
	} else {
	  $total = scalar(@handles);
	} 

	return $total;
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	
	$self->SUPER::print();
	return;
  }

#=============================================================================
sub remove_stream
  {
    my $self   = shift;
	my $handle = shift;

	return FALSE if ( &valid_string($handle) eq FALSE );
	return FALSE if ( $self->has_handle($handle) eq FALSE );

	if ( $self->shutdown_stream($handle) eq TRUE ) {	
      my $known_streams = $self->known_handles();
	  delete($known_streams->{$handle});
	  return TRUE;
	}
	return FALSE;
  }

#=============================================================================
sub shutdown_stream
  {
    my $self   = shift;
	my $handle = shift;
	
	return FALSE if ( &valid_string($handle) eq FALSE );
	return FALSE if ( $self->has_handle($handle) eq FALSE );
 
    my $strmobj = $self->known_handles()->{$handle};
	if ( defined($strmobj) ) {
	  my $closed = ( &UNIVERSAL::can($strmobj, 'close') ) ? $strmobj->close() : TRUE;
      my $result = ( $strmobj->close() ne FALSE ) ? TRUE : FALSE;
      return $result;
	}
	return FALSE;
  }
  
#=============================================================================
sub shutdown_all_streams
  {
    my $self = shift;
	my $known_streams = $self->known_handles();
	my @handles = keys(%{$known_streams});

	foreach ( @handles ) {
	  next if ( $known_streams->{$_}->is_system() eq TRUE );
	  $self->shutdown_stream($_);
	}
	return;
  }

#=============================================================================
sub streams
  {
    my $self = shift;
	my $known_streams = $self->known_handles();
	my @handles = keys(%{$known_streams});

	my $streams = &create_object('c__HP::ArrayObject__');
	return [] if ( not defined($streams) );
	
	foreach ( @handles ) {
	  $streams->push_item($known_streams->{$_});
	}
	
	return $streams;
  }
  
#=============================================================================
sub touch_file
  {
    my $self = shift;
	my $path = shift || return FALSE;
	
	my $dirname = File::Basename::dirname("$path");
	&make_recursive_dirs("$dirname") if ( &does_directory_exist("$dirname") eq FALSE );
	
	$self->make_stream("$path", OUTPUT, '__TOUCH__');
	my $result = $self->remove_stream('__TOUCH__');
	return $result;
  }
  
#=============================================================================
sub validate
  {
    my $self = shift;
	
	$self->SUPER::validate();
	$self->valid(TRUE);
	return;
  }

#=============================================================================
1;