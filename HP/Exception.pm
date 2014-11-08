package HP::Exception;

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

	use overload q{""} => 'HP::Exception::print';

	use parent qw(Class::Throwable);
	
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
							'HP::Constants'                => undef,
							'HP::Base::Constants'          => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Exception::Constants'     => undef,
							
	                        'HP::CheckLib'                 => undef,
							'HP::Utilities'                => undef,
							
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_exception_pm'} ||
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
sub add_data
  {
    my $self    = shift;
	
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'key',     \&valid_string,
	                                        'value',   \&valid_string,
											'builtin', \&is_integer ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $key     = $inputdata->{'key'} || return;
    my $value   = $inputdata->{'value'};
    my $builtin = $inputdata->{'builtin'} || TRUE;
	
	if ( &is_type($self->{"$key"}, 'HP::ArrayObject') eq TRUE ) {
	  $self->{"$key"}->add_elements({'entries' => $value});
	} else {
	  $self->{"$key"} = $value;
	}
	
	$self->update_fields("$key") if ( $builtin eq FALSE );
	return;
  }
  
#=============================================================================
sub add_handle
  {
    my $self   = shift;
	my $handle = shift;

	return FALSE if ( &valid_string($handle) eq FALSE );
	return $self->handles()->push_item($handle);
  }

#=============================================================================
sub add_handles
  {
    my $self = shift;
	my $hdls = shift;
	
	my $result = TRUE;
	
	if ( &is_type($hdls, 'HP::ArrayObject') eq TRUE ) {
	  foreach ( @{$hdls->get_elements()} ) {
	    $result = $result && $self->add_handle($_);
		last if ( $result eq FALSE );
	  }
	} elsif ( ref($hdls) =~ m/^array/i ) {
	  foreach ( @{$hdls} ) {
	    $result = $result && $self->add_handle($_);
		last if ( $result eq FALSE );
	  }
	}
    return $result;
  }

#=============================================================================
sub add_message
  {
    my $self = shift;
	my $msg  = shift;
	
	return FALSE if ( &valid_string($msg) eq FALSE );
	return $self->message()->push_item($msg);
  }

#=============================================================================
sub add_messages
  {
    my $self = shift;
	my $msgs = shift;
	
	my $result = TRUE;
	
	if ( &is_type($msgs, 'HP::ArrayObject') eq TRUE ) {
	  foreach ( @{$msgs->get_elements()} ) {
	    $result = $result && $self->add_message($_);
		last if ( $result eq FALSE );
	  }
	} elsif ( ref($msgs) =~ m/^array/i ) {
	  foreach ( @{$msgs} ) {
	    $result = $result && $self->add_message($_);
		last if ( $result eq FALSE );
	  }
	}
    return $result;
  }
  
#=============================================================================
sub AUTOLOAD
  {
    our $AUTOLOAD;
    my $self = shift;
    my $type = ref($self) or die "\$self is not an object when calling method << $AUTOLOAD >>\n";
    
    # DESTROY messages should never be propagated.
    return if $AUTOLOAD =~ /::DESTROY$/;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    unless ( defined($name) or exists($self->{$name}) ) {
      if ( defined($name) ) {
	    &__print_output("Can't access '$name' field in class $type.  Returning empty string...\n", 'STDERR');
      } else {
	    &__print_output("Can't access an undefined field in class $type.  Returning empty string...\n", 'STDERR');
      }
      return undef;
    }

    my $num_elements = scalar( @_ );

    if ( $num_elements >= 1) {
      # Set built-on-the-fly function...
      if ( $num_elements == 1 ) {
	    return $self->{$name} = $_[0];
      } else {
	    return $self->{$name} = \@_;
      }
    } else {
      # Get built-on-the-fly function...
      return $self->{$name};
    }
  }

#=============================================================================
sub clear
  {
    my $self = shift;
	
	$self->errorcode(DEFAULT_ERROR_CODE);
	$self->message()->clear();
	$self->handles()->clear();
	$self->severity(ERROR);
	
	$self->SUPER::clear() if ( &is_type($self, 'HP::Exception') eq FALSE );
  }

#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'errorcode' => DEFAULT_ERROR_CODE,
	                   'message'   => 'c__HP::Array::Queue__',
					   'handles'   => 'c__HP::Array::Set__',
					   'severity'  => ERROR,
		              };
    
	if ( $which_fields eq COMBINED ) {
      foreach ( @ISA ) {
	    my $parent_types = undef;
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
		if ( ! $@ ) {
	      $data_fields = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	    }
	  }
	}
	
	return $data_fields;
  }
  
#=============================================================================
sub DESTROY
  {
    my $self = shift;

    &__print_debug_output("Calling destructor for object ".ref($self)."\n") if ( $is_debug );
	return;
  }

#=============================================================================
sub display
  {
    my $self = shift;
	my $stream_db = undef;
	
	my $evalstr = "use HP::DBContainer; \$stream_db = \&getDB('stream');";
	eval "$evalstr";
	
	if ( ! $@ ) {
	  if ( defined($stream_db) ) {
	    foreach my $h ( @{$self->handles()} ) {
	      my $stream = $stream_db->find_stream_by_handle("$h");
	      $stream->output($self->get_message(), $self->severity()) if ( &is_type($stream, 'HP::Stream') eq TRUE );
	    }
	  }
	}
	return;
  }

#=============================================================================
sub get_message
  {
    my $self = shift;
	
	return '<NO MESSAGE>' if ( $self->message()->is_empty() eq TRUE );
	my $msgcomps = $self->message()->get_elements();
	return join("\n", @{$msgcomps});
  }
  
#=============================================================================
sub instantiate
  {
    my $self = shift;
	#return if ( ref($self) eq 'HP::Exception' );
	
	my $data_fields = $self->data_types();

	foreach ( keys ( %{$data_fields} ) ) {
	  my $result = &is_class_rep($self->{"$_"});
	  if ( defined($result->{'class'}) ) {
		$self->add_data($_, &HP::Support::Object::Tools::__convert_to_structure($result));
	  }
    }

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
    my $self        = shift;
	my $indentation = shift || '';
	
    my $result  = '';
	
	my $handles = $self->handles();
	my $num_handles = $handles->number_elements();
	
	$result .= &print_object_header($self, $indentation) ."\n\n";
    $result .= &print_string($self->message(), 'Exception Message', $indentation). "\n";
	$result .= &print_string($num_handles, 'Number of Streams', $indentation). "\n";
	
	$result .= "\n" if ( $num_handles > 0 );
	
	my $cnt = 1;
	foreach ( @{$self->handles()->get_elements()} ) {
	  $result .= "$cnt) $_\n" if ( &valid_string($_) eq TRUE );
	  ++$cnt;
	}
	
	return $result;
  }

#=============================================================================
sub set_error_code
  {
    my $self  = shift;
	my $errid = shift;
	
	return FALSE if ( &valid_string($errid) eq FALSE );
	$errid = abs($errid) if ( $errid < 0 );
	$self->{'errorcode'} = $errid;
	return TRUE;
  }

#=============================================================================
sub set_handle
  {
    my $self = shift;
	my $hndl = shift;
	
	return FALSE if ( &valid_string($hndl) eq FALSE );
	$self->handles()->clear();
	return $self->handles()->push_item($hndl);  
  }
  
#=============================================================================
sub set_message
  {
    my $self = shift;
	my $msg  = shift;
	
	return FALSE if ( &valid_string($msg) eq FALSE );
	$self->message()->clear();
	return $self->message()->push_item($msg);
  }

#=============================================================================
sub set_severity
  {
    my $self = shift;
	my $sev  = shift;
	
	return FALSE if ( &valid_string($sev) eq FALSE );
	return FALSE if ( not exists(SEVERITY->{"$sev"}) );
	
	$self->severity($sev);
	return TRUE;
  }
  
#=============================================================================
sub throw
  {
    my $self = shift;
	$self->display();
	$self->SUPER::throw($self->message());
	return;
  }
  
#=============================================================================
sub update_fields
  {
    my $self = shift;
	my $key  = shift || return;
	
	if ( not defined($self->{'ADDED_FIELDS'}) ) {
	  $self->{'ADDED_FIELDS'} = &create_object('c__HP::Array::Set__');
	}
	$self->{'ADDED_FIELDS'}->push_item("$key");
	return;
  }
  
#=============================================================================
1;