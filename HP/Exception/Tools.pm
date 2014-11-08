package HP::Exception::Tools;

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
    use lib "$FindBin::Bin/../..";

    use vars qw(
				$VERSION
				$is_debug
				$is_init

				$module_require_list
                $module_request_list

				$broken_install

                $module_callback
		
				@ISA
				@EXPORT
               );

    $VERSION  = 0.85;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
	             &add_exception_mapping
				 &make_exception
				 &raise_exception
				 &show_exception_map
				 &translate_exception_id
				);

    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Base'            => undef,							
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Exception::Constants'     => undef,
							
							'HP::CheckLib'                 => undef,
							'HP::Array::Tools'             => undef,
							'HP::DBContainer'              => undef,
						   };
    $module_request_list = {
	                       };

    $module_callback     = {};

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_exception_tools_pm'} ||
			$ENV{'debug_exception_modules'} ||
			$ENV{'debug_hp_modules'} ||
			$ENV{'debug_all_modules'} || 0
		);

    $broken_install = 0;

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
	if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
          eval "use $usemod;";
        }
	if ( $@ ) {
	  print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub add_exception_mapping($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'name',  \&valid_string,
	                                        'num',   \&valid_string,
											'class', \&valid_string, ], @_);
    } else {
      $inputdata = $_[0];
    }
	
    my $exception_name  = $inputdata->{'name'};
	my $exception_num   = $inputdata->{'num'};
	my $exception_class = $inputdata->{'class'};

	my $exDB = &getDB('exceptions');
	
	# Non-integer value provided or outside allowed limits or previously exists...
	return NO_EXCEPTION_INSTALLED if ( &is_integer($exception_num) eq FALSE );
	return NO_EXCEPTION_INSTALLED if ( $exception_num < MINIMUM_ERROR_CODE || $exception_num > MAXIMUM_ERROR_CODE );
	return NO_EXCEPTION_INSTALLED if ( $exDB->has_exception('id', "$exception_num") eq TRUE );
	
    return NO_EXCEPTION_INSTALLED if ( &valid_string($exception_name) eq FALSE );
	return NO_EXCEPTION_INSTALLED if ( $exDB->has_exception('name', "$exception_name") eq TRUE );
	
    return NO_EXCEPTION_INSTALLED if ( &valid_string($exception_class) eq FALSE );

	my $classification = &is_class_rep($exception_class);
	return NO_EXCEPTION_INSTALLED if ( &valid_string($classification->{'class'}) eq FALSE );
	
	if ( $exDB->add_exception_type($exception_name, [ $exception_num, $exception_class ]) eq TRUE ) {
	  return EXCEPTION_INSTALLED;
	}
	return NO_EXCEPTION_INSTALLED;
  }	

#=============================================================================
sub show_exception_map(;$)
  {
    my $stream   = shift;
	my $streamDB = &getDB('stream');
	
	my $tmpfilehandle = undef;
	
	if ( defined($stream) ) {
	  if ( &is_type($stream, 'HP::Stream') eq FALSE ) {
	    my $reftype = ref($stream);
	    if ( $reftype =~ m/^glob/i || $reftype =~ m/^io/i ) {
		  $tmpfilehandle = '__TEMPORARY_STREAM_EXCEPTION_MAP__';
		  $stream = $streamDB->__install_system_stream( {
	                                                     'HANDLE'   => $tmpfilehandle,
					                                     'ACTIVE'   => TRUE,
									                     'FILEGLOB' => $stream,
									                    } );
		} elsif ( $reftype eq '' ) {
		  my $streamobj = $streamDB->find_stream_by_handle($stream);
		  
		  if ( defined($streamobj) ) {
		    $stream = $streamobj;
			goto PRINT_MAP;
		  }
		  
		  &__print_output("No stream by name of <$stream> was located.  Using STDERR...", WARN);
		  $stream = $streamDB->find_stream_by_handle('STDERR');
		}
	  } else {
	    if ( &is_type($stream, 'HP::Stream::IO::Output') eq FALSE ) {
	      $stream = $streamDB->find_stream_by_handle('STDERR');
		  &__print_output("Stream provided is an input stream.  Using STDERR...", WARN);
		}
	  }
	} else {
	  $stream = $streamDB->find_stream_by_handle('STDERR');
	}

  PRINT_MAP:
	$stream->output("Exception #    Exception Name    Exception Class");
	
	my $exDB = &getDB('exceptions');
	
	foreach ( @{$exDB->get_known_exceptions()->get_elements()} ) {
	  my $exname  = $_->get_exception_name();
	  my $exnum   = $_->get_exception_id();
	  my $exclass = $_->get_exception_class();
	  $stream->output("\t$exnum\t\t$exname\t\t$exclass");
	}
	
    if ( defined($tmpfilehandle) ) {
	  if ( $streamDB->remove_stream($tmpfilehandle) eq FALSE ) {
	    &__print_output("Unable to remove temporary handle from StreamDB!", WARN);
	  }
	}
	
	return;
  }
  
#=============================================================================
sub make_exception($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $input = shift || return undef;
	
	if ( ref($input) !~ m/hash/i ) {
	  my $type = $input;
	  $input = {
	            'type' => 'c__'. $type .'__',
			   };
	} else {
	  if ( $input->{'type'} !~ m/^c__(\w*\:?\:?.*)__/ ) {
	    $input->{'type'} = 'c__'. $input->{'type'} .'__';
	  }
	}
	
	my $exception_type = $input->{'type'};
	my $exDB = &getDB('exceptions');
	
	my $obj = $exDB->make_exception('method', $input->{'type'});
	if ( not defined($obj) ) {
	  &__print_output("Generating standard exception since could not find <$exception_type>", WARN);
	  $obj = &create_object('c__HP::Exception__');
	}
	
	$obj->{'message'}->push_item($input->{'addon_msg'}) if ( exists($input->{'addon_msg'}) );
	
	return $obj;
  }

#=============================================================================
sub raise_exception(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $exception = shift;
	if ( &is_type($exception, 'HP::Exception') eq FALSE ) {
	  if ( ref($exception) =~ m/hash/i ) {
	    $exception->{'type'} = &translate_exception_id($exception->{'type'});
        $exception = &make_exception($exception, @_);
	  }
	}
	
	$exception->display();
	return if ( exists($exception->{'bypass'}) && $exception->{'bypass'} eq TRUE );
	
	if ( exists($exception->{'callback'}) ) {
	  if ( ref($exception->{'callback'}) =~ m/code/i ) {
	    if ( exists($exception->{'arguments'}) ) {
		  &{$exception->{'callback'}($exception->{'arguments'})};
		} else {
		  &{$exception->{'callback'}($exception->errorcode())};
		}
		return;
	  } else {
	    eval "&$exception->{'callback'}($exception->{'arguments'})";
		if ( $@ ) { die "Unable to properly execute callback [ $exception->{'callback'} ]"; }
		return;
	  }
	}
	exit $exception->errorcode();
  }
  
#=============================================================================
sub translate_exception_id($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $exceptionID = shift || 255;
	
	#if ( &is_integer($exceptionID) eq TRUE ) {
	#  $exceptionID = $exceptions_by_num->{$exceptionID};
	#}
	
	#my $edata = $exceptions_by_name->{$exceptionID} || $exceptionID;
	#return $edata;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;