package HP::Job;

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

	use overload q{""} => 'HP::Job::print';
	
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

    $VERSION = 0.975;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'              => undef,
	                        'HP::Support::Base'          => undef,
							'HP::Support::Object'        => undef,
							'HP::Support::Object::Tools' => undef,
							'HP::Support::Hash'          => undef,
							
							'HP::CheckLib'               => undef,
	                        'HP::Process'                => undef,
							'HP::String'                 => undef,
							'HP::Array::Constants'       => undef,
							'HP::Array::Tools'           => undef,
							'HP::Utilities'              => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_job_pm'} ||
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
sub __add_item
  {
    my $self     = shift;
	my $type     = shift;
	my $new_item = shift;
	my $location = shift;
	
	$location = APPEND if ( &valid_string($location) eq FALSE );
	
	return if ( &valid_string($type) eq FALSE );
	return if ( &valid_string($new_item) eq FALSE );
	
	return if ( not exists( $self->{"$type"} ) );

	if ( &is_type($new_item, 'HP::ArrayObject') eq TRUE ) {
      $new_item = $new_item->get_elements();
	}
	
	my $ref_type = ref($new_item);
	
	if ( $ref_type =~ m/^array/i ) {
	  foreach ( @{$new_item} ) {
	    $self->__add_item($type, $_, $location);
	    $location += 1 if ( $location ne APPEND );
	  }
	} elsif ( $ref_type =~ m/hash/i ) {
	  my $flag = &create_object('c__HP::Job::ExecutableFlag__');
	  $flag->set_name( $new_item->{'name'} ) if ( exists($new_item->{'name'}) );
	  $flag->set_value( $new_item->{'value'} ) if ( exists($new_item->{'value'}) );
	  $flag->set_connector( $new_item->{'connector'} ) if ( exists($new_item->{'connector'}) );
	  $self->__add_item($type, $flag, $location) if ( $flag-> valid() eq TRUE );
	} elsif ( $ref_type =~ m/scalar/i ) {
	  $self->__add_item($type, ${$new_item}, $location);
	} else {
	  if ( &is_type($new_item, 'HP::Job::ExecutableFlag') eq TRUE ) {
	    $self->{"$type"}->push_item($new_item, $location);
	  } else {
	    my $proper_item = &get_template_obj($self->{"$type"});
	    if ( defined($proper_item) ) {
	      my $flag = $proper_item->clone();
		  $flag->set_name( $new_item );
		  $self->{"$type"}->push_item($flag, $location) if ( $flag->valid() eq TRUE );
		} else {
		  $self->{"$type"}->push_item($new_item, $location);
		}
	  }
	}
	
	$self->validate();
    return;
  }  

#=============================================================================
sub __remove_item
  {
    my $self     = shift;
	my $type     = shift;
	my $old_item = shift;
	
	return if ( &valid_string($type) eq FALSE );
	return if ( &valid_string($old_item) eq FALSE );
	
	return if ( not exists( $self->{"$type"} ) );
	
	if ( &is_type($old_item, 'HP::ArrayObject') eq TRUE ) {
      $old_item = $old_item->get_elements();
	}
	
	my $ref_type = ref($old_item);
	
	if ( $ref_type =~ m/^array/i ) {
	  foreach ( @{$old_item} ) {
	    $self->__remove_item($type, $_);
	  }
	} elsif ( $ref_type =~ m/hash/i ) {
	  my $flag = &create_object('c__HP::Job::ExecutableFlag__');
	  $flag->set_name( $old_item->{'key'} ) if ( exists($old_item->{'key'}) );
	  $flag->set_value( $old_item->{'value'} ) if ( exists($old_item->{'value'}) );
	  $self->__remove_item($type, $flag) if ( $flag->valid() eq TRUE );
	} elsif ( $ref_type =~ m/scalar/i ) {
	  my $found_loc = $self->find_flag(${$old_item});
	  if ( $found_loc ne NOT_FOUND ) {
	    $self->{"$type"}->delete_elements_by_index($found_loc);
	  }
	  #$self->{"$type"}->delete_elements(${$old_item});
	} else {
	  my $found_loc = $self->find_flag($old_item);
	  if ( $found_loc ne NOT_FOUND ) {
	    $self->{"$type"}->delete_elements_by_index($found_loc);
	  }
	  #$self->{"$type"}->delete_elements($old_item);
	}

	$self->validate();
	return;
  }

#=============================================================================
sub add_flags
  {
    my $self          = shift;
	my $new_parameter = shift;
	my $location      = shift;
	
	$location = APPEND if ( &valid_string($location) eq FALSE );
	
	return $self->__add_item('flags', $new_parameter, $location);
  }
  
#=============================================================================
sub convert_output
  {
    my $self     = shift;
	my $specific = { 'completed' => { &FORWARD => [ 'bool2string', __PACKAGE__ ], &BACKWARD => [ 'string2bool', __PACKAGE__ ] } };
	
	$specific = &HP::Support::Hash::__hash_merge($specific, $self->SUPER::convert_output());
	return $specific;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'executable'   => 'c__HP::Job::Executable__',
					   'flags'        => '[] c__HP::Job::ExecutableFlag__',
					   'output'       => 'c__HP::Job::JobOutput__',
					   'pid'          => undef,
					   'error_status' => FAIL,
					   'completed'    => FALSE,
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
sub get_cmd
  {
    my $self = shift;

	my @results = ();
	
	push( @results, $self->get_executable() );
	push( @results, $self->get_flags() );
	
	return join(' ', @results);
  }
  
#=============================================================================
sub get_error_status
  {
    my $self = shift;
	return $self->error_status();
  }
  
#=============================================================================
sub get_executable
  {
    my $self   = shift;
	my $result = undef;
	
	if ( $self->executable()->valid() eq TRUE ) {
	  $result = $self->executable()->get_executable();
	}
	return $result;
  }

#=============================================================================
sub get_file_err
  {
    my $self = shift;
	if ( not defined( $self->output()) ) { return undef; }
	
	return $self->output()->file_err();
  }
  
#=============================================================================
sub get_file_error_contents
  {
    my $self = shift;
	if ( not defined( $self->output()) ) { return []; }
	
	return $self->output()->stderr();
  }
  
#=============================================================================
sub get_file_out
  {
    my $self = shift;
	if ( not defined( $self->output()) ) { return undef; }
	
	return $self->output()->file_out();
  }
  
#=============================================================================
sub get_file_output_contents
  {
    my $self = shift;
	if ( not defined( $self->output()) ) { return []; }
	
	return $self->output()->stdout();
  }

#=============================================================================
sub get_flag_at
  {
    my $self     = shift;
	my $location = shift;

	$location = APPEND if ( &valid_string($location) eq FALSE );
	
	if ( $location eq APPEND ) {
	  return $self->flags()->get_element(-1);
	} elsif ( $location eq PREPEND ) {
	  return $self->flags()->get_element(0);
	} else {
	  return $self->flags()->get_element($location);
	}
  }
  
#=============================================================================
sub get_flags
  {
    my $self   = shift;
	my $result = [];
	
	my $flags = $self->flags();
	foreach my $f ( @{$flags->get_elements()} ) {
	  if ( $f->valid() eq TRUE ) {
	    my $flagdef = $f->get_flag();
	    push ( @{$result}, $flagdef ) if ( &valid_string($flagdef) eq TRUE );
	  }
	}
	
	return join(' ', @{$result});
  }
  
#=============================================================================
sub get_job_contents
  {
    my $self     = shift;
    my @contents = ();
	
	push( @contents, @{$self->get_file_output_contents()} );
	push( @contents, @{$self->get_file_error_contents()} );
	
	return \@contents;
  }

#=============================================================================
sub find_flag
  {
    my $self   = shift;
	my $item   = shift;
	my $result = [];
	
	return NOT_FOUND if ( &valid_string($item) eq FALSE );
	
	my $elements = $self->flags()->get_elements();
	for ( my $loop = 0 ; $loop < scalar(@{$elements}); ++$loop ) {
	  if ( &is_type($item, 'HP::Job::ExecutableFlag') eq FALSE ) {
	    CORE::push( @{$result}, $loop ) if ( $elements->[$loop]->name() eq $item );
	  } else {
	    CORE::push( @{$result}, $loop ) if ( $elements->[$loop]->name() eq $item->name() );
	  }
	}
	
	my $num_matches = scalar(@{$result});
	if ( $num_matches == 0 )  {
	  return NOT_FOUND;
	} elsif ( $num_matches == 1 ) {
	  return $result->[0];
	} else {
	  return $result;
	}
	
	return NOT_FOUND;
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
	$self->instantiate();	$self->install_exceptions();
    return $self;  
  }

#=============================================================================
sub print
  {
    my $self        = shift;
	my $indentation = shift || '';
	
	my $result = '';
	$result .= &print_object_header($self, $indentation) ."\n";

	my $subindent = $indentation . "\t";
	
	$result .= $self->executable()->print($subindent) ."\n";
	$result .= $self->flags()->print($subindent) ."\n";
	$result .= $self->output()->print($subindent) ."\n";
	$result .= &print_string($self->pid(), 'PID', $indentation) ."\n";
	$result .= &print_status($self->error_status(), 'Error Status     ', $indentation) ."\n";
	$result .= &print_boolean($self->completed() , 'Completion Status', undef, $indentation) ."\n";
	
	return $result;
  }
  
#=============================================================================
sub remove_flags
  {
    my $self          = shift;
	my $old_parameter = shift;

	return $self->__remove_item('flags', $old_parameter);
  }
  
#=============================================================================
sub reset
  {
    my $self = shift;
	
	$self->completed(FALSE);
	$self->output()->clear();
	$self->error_status(FAIL);
	$self->pid(undef);
	
	$self->validate();
  }
  
#=============================================================================
sub run
  {
    my $self  = shift;
	my $rerun = shift || FALSE;
	
	return if ( $self->valid() eq FALSE );
	
	if ( $rerun ne FALSE || $self->completed() eq FALSE ) {	  
	  my $cmd  = $self->get_executable();
	  return if ( not defined($cmd) );
	  
	  my $args = $self->get_flags();
	  
	  $self->completed(FALSE);
	  
	  # Low-Level workings... (may need refactoring)
	  my ( $unix_result, $stdout, $stderr, $otherdata ) = &runcmd(
                                                                  {
													               'command'   => "$cmd",
	                                                               'arguments' => "$args",
													               'verbose'   => $is_debug,
													              }
												                 );
	  $self->error_status($unix_result);
	  $self->output->stdout($stdout);
	  $self->output->stderr($stderr);
	
	  if ( defined($otherdata) ) {
	    $self->pid($otherdata->{'pid'}) if ( exists($otherdata->{'pid'}) );
	    $self->output()->file_out(&eat_quotations($otherdata->{'output_file'})) if ( exists($otherdata->{'output_file'}) );
	    $self->output()->file_err(&eat_quotations($otherdata->{'error_file'})) if ( exists($otherdata->{'error_file'}) );
	  }
	  
	  $self->completed(TRUE);
	}
	return;
  }

#=============================================================================
sub scan_for_errors
  {
    my $self           = shift;
	my $error_strings  = shift || [];
	my $error_detected = FALSE;
	
	$error_strings = &convert_to_array($error_strings, TRUE) if ( ref($error_strings) !~ m/^array/i );
	
	return $error_detected if ( scalar(@{$error_strings}) < 1 );
	
	if ( $self->completed() eq TRUE && $self->valid() eq TRUE ) {
	  my $all_output = $self->get_job_contents();
	  foreach ( @{$all_output} ) {
	    next if ( &valid_string($_) eq FALSE );
		my $result = &str_matches("$_", $error_strings);
	    if ( $result eq TRUE ) {
		  $error_detected = TRUE;
		  last;
		}
	  }
	}
	
	return $error_detected;
  }
  
#=============================================================================
sub set_executable
  {
    my $self       = shift;
	my $exe        = shift || return;
	my $is_builtin = shift || FALSE;
	
	my $ref_type = ref("$exe");
	
	if ( &is_type($exe, 'HP::Job::Executable') eq TRUE ) {
	  $self->{'executable'} = $exe if ( $exe->valid() eq TRUE );
	  $self->validate();
	  return;
	}

	if ( $ref_type eq '' ) {
	  my $exeobj = &create_object('c__HP::Job::Executable__');
	  if ( $is_builtin eq FALSE ) {
	    $exeobj->set_executable($exe);
	  } else {
	    $exeobj->{'executable'} = $exe;
		$exeobj->valid(TRUE);
      }
	  $self->executable( $exeobj );
	}

	return $self->set_executable(${$exe}) if ( $ref_type =~ m/^scalar/i );

	$self->validate();
	return;
  }

#=============================================================================
sub validate
  {
    my $self = shift;
	
	$self->SUPER::validate();
	
	my $exe   = $self->executable();
	my $flags = $self->flags();
	
	if ( $exe->valid() eq FALSE ) {
	  $self->valid(FALSE);
	  return;
	}
	
	my $num_flags         = $flags->number_elements();
	my $num_invalid_flags = 0;
	
	foreach my $f ( @{$flags->get_elements()} ) {
	  if ( $f->valid() eq FALSE ) {
		++$num_invalid_flags;
		next;
	  }
	}
	
	if ( $num_flags > 0 ) {
	  ( $num_invalid_flags == $num_flags) ? $self->valid(FALSE) : $self->valid(TRUE);
	}
	
	return;
  }

#=============================================================================
1;